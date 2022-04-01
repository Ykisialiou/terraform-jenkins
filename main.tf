resource "kubernetes_namespace" "jenkins_namespace" {
  metadata {
    annotations = {
      name = var.app_name
    }
    labels = var.common_labels
    name   = var.namespace
  }
}
// PVC: Will go to separate file


resource "kubernetes_persistent_volume_claim" "jenkins_claim" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels    = var.common_labels
  }
  spec {
    access_modes = [var.accessmode]
    resources {
      requests = {
        storage = var.pvc_size
      }
    }
    storage_class_name = var.storage_class_name
  }

}


// Secrets and configmaps

//generate random password
resource "random_password" "password" {
  count = var.jenkins_password ? 0 : 1
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "admincreds" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels    = var.common_labels
  }

  data = {
    jenkins-admin-user     = var.jenkins_admin_name
    jenkins-admin-password = var.jenkins_password ? 0 : random_password.password.0.result
  }

}

// ConfigMAPs
resource "kubernetes_config_map" "initscript" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels    = var.common_labels
  }

  data = {
    "apply_config.sh" = "${file("${path.module}/templates/apply_config.sh")}"
    "plugins.txt"     = "${file("${path.module}/templates/plugins.txt")}"
  }
}

resource "kubernetes_config_map" "jcasc" {
  metadata {
    name      = "${var.app_name}-jenkins-jcasc-config"
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels    = var.common_labels
  }

  data = {
    "jcasc-default-config.yaml" = data.template_file.jcasc_config.rendered
  }

}

// RBAC: Will go to separate file

resource "kubernetes_service_account" "jenkins-controller-sa" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels    = var.common_labels
  }
}

resource "kubernetes_cluster_role_binding" "jenkins-rbac" {
  metadata {
    name = "${var.app_name}}-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      =  kubernetes_cluster_role.jenkins-controller-role.metadata.0.name //"cluster-admin" 
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins-controller-sa.metadata.0.name
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
  }
}


resource "kubernetes_cluster_role" "jenkins-controller-role" {
  metadata {
    name = "${var.app_name}}-controller-role"
    labels    = var.common_labels
  }

  rule {
    api_groups     = [""]
    resources      = [
      "pods",
      "pods/exec",
      "pods/log",
      "persistentvolumeclaims",
      "events"
    ]
    verbs          = [
      "get", 
      "list", 
      "watch"
    ]
  }
  rule {
    api_groups = [""]
    resources  = [
      "pods",
      "pods/exec",
      "persistentvolumeclaims"
    ]
    verbs      = [
      "create",
      "delete",
      "deletecollection",
      "patch",
      "update"
    ]
  }
}


// Services

resource "kubernetes_service" "jenkins-service" {

  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels    = var.common_labels
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      port        = 8080
      name        = "http"
      protocol    = "TCP"
      target_port = 8080
      node_port   = var.controller_node_port
    }
    port {
      port        = 50000
      name        = "agent"
      protocol    = "TCP"
      target_port = 50000
    }
    type = "NodePort"
  }
}

// Jenkins controller's SF
resource "kubernetes_stateful_set" "jenkins_controller_stfset" {
  metadata {
    name      = "${var.app_name}-stfset"
    namespace = kubernetes_namespace.jenkins_namespace.metadata.0.name
    labels = {
      managed-by = "terraform"
      name       = var.app_name
      version    = var.jenkins_version
    }
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = var.revision_history_limit

    selector {
      match_labels = {
        app = var.app_name
      }
    }
    service_name = var.app_name

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.jenkins-controller-sa.metadata.0.name

        init_container {
          name              = "init"
          image             = var.jenkins_image
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "/var/jenkins_config/apply_config.sh"]

          dynamic "volume_mount" {
            for_each = var.init_volume_mounts
            content {
              name       = volume_mount.value["name"]
              mount_path = volume_mount.value["mount_path"]
            }
          }

        }
        container {
          name              = var.app_name
          image             = var.jenkins_image
          image_pull_policy = "IfNotPresent"

          args = [
            "--httpPort=8080"
          ]

          dynamic "port" {
            for_each = var.controller_ports
            content {
              container_port = port.value["port"]
            }
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }

          dynamic "env" {
            for_each = var.controller_env_vars
            content {
              name  = env.value["name"]
              value = env.value["value"]
            }
          }

          dynamic "volume_mount" {
            for_each = var.controller_volume_mounts
            content {
              name       = volume_mount.value["name"]
              mount_path = volume_mount.value["mount_path"]
            }
          }

          volume_mount {
            name       = "admin-secret"
            mount_path = "/run/secrets/jenkins-admin-password"
            read_only  = true
            sub_path   = "jenkins-admin-password"
          }

          resources {
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }

            requests = {
              cpu    = "50m"
              memory = "256Mi"
            }
          }
        }
        
        dynamic "volume" {
          for_each = var.controller_sts_empty_dir_volumes
            content {
              name  = volume.value["name"]
              empty_dir {}
              
            }
        }

        volume {
          name = "sc-config-volume"
          config_map {
            name = kubernetes_config_map.jcasc.metadata.0.name
          }
        }
        volume {
          name = "jenkins-config"
          config_map {
            name = kubernetes_config_map.initscript.metadata.0.name
          }
        }
        volume {
          name = "admin-secret"
          secret {
            secret_name = kubernetes_secret.admincreds.metadata.0.name
          }
        }
        volume {
          name = "jenkins-home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_claim.metadata.0.name
          }
        }

      }
    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }
  }
}
