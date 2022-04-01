variable "init_volume_mounts" {
  description = "map of volume mounts for init container"
  default = [
    {
      name       = "jenkins-home"
      mount_path = "/var/jenkins_home"
    },
    {
      name       = "jenkins-config"
      mount_path = "/var/jenkins_config"
    },
    {
      name       = "plugins"
      mount_path = "/usr/share/jenkins/ref/plugins"
    },
    {
      name       = "tmp-volume"
      mount_path = "/tmp"
    },
    {
      name       = "plugin-dir"
      mount_path = "/var/jenkins_plugins"
    }
  ]

}

variable "controller_env_vars" {
  description = "map of env vars for controller container"
  default = [
    {
      name  = "JAVA_OPTS"
      value = "-Dcasc.reload.token=$(POD_NAME) "
    },
    {
      name  = "JENKINS_OPTS"
      value = "--webroot=/var/jenkins_cache/war "
    },
    {
      name  = "JENKINS_SLAVE_AGENT_PORT"
      value = "50000"
    },
    {
      name  = "CASC_JENKINS_CONFIG"
      value = "/var/jenkins_home/casc_configs"
    }
  ]
}

variable "controller_volume_mounts" {
  description = "map of volume mounts for controller container"
  default = [
    {
      name       = "jenkins-home"
      mount_path = "/var/jenkins_home"
    },
    {
      name       = "jenkins-config"
      mount_path = "/var/jenkins_config"
    },
    {
      name       = "plugins"
      mount_path = "/usr/share/jenkins/ref/plugins"
    },
    {
      name       = "tmp-volume"
      mount_path = "/tmp"
    },
    {
      name       = "sc-config-volume"
      mount_path = "/var/jenkins_home/casc_configs"
    },
    {
      name       = "jenkins-cache"
      mount_path = "/var/jenkins_cache"
    }
  ]
}

variable "controller_ports" {
  description = "map of ports for controller container"
  default = [
    {
      port = 8080
    },
    {
      port = 50000
    }
  ]
}


variable "controller_sts_empty_dir_volumes" {
  default = [
    {
      name       = "plugins"
    },
    {
      name       = "tmp-volume"
    },
    {
      name       = "plugin-dir"
    },
    {
      name       = "jenkins-cache"
    }    
  ]  
}

variable "jenkins_password" {
  description = "Setup Jenkins password here. If not, it will be securely generated (Recommended)"
  default = "0"
}

variable "controller_node_port" {
  default = 30080
  description = "NodePort where controller UI will listen"
}

variable "k8s_context" {
  default = "minikube"
}

variable "namespace" {
  default = "jenkins"
}

variable "app_name" {
  default = "jenkins"
}

variable "jenkins_version" {
  default = "minikube"
}

// Controller sts configuration

variable "replicas" {
  default = "1"
}

variable "revision_history_limit" {
  default = "5"
}

variable "service_account_name" {
  default = "jenkins"
}

// Images
variable "jenkins_image" {
  description = "Jenkins docker image"
  default     = "jenkins/jenkins:2.332.1-jdk11"
}

variable "config_reload_image" {
  description = "Config reload image"
  default     = "kiwigrid/k8s-sidecar:1.15.0"
}

// PVC

variable "accessmode" {
  default = "ReadWriteOnce"
}

variable "pvc_size" {
  description = "storage for your jenkins installation"
  default     = "5Gi"
}

variable "storage_class_name" {
  description = "storage for your jenkins installation"
  default     = "standard"
}

//secrets

variable "jenkins_admin_name" {
  description = "Username to use for admin login"
  default     = "admin"
}

//labels
variable "common_labels" {
  description = "Common labels used for all k8s resources"
  default = {
    managed-by = "terraform"
    name       = "jenkins"
    env_name   = "test"
  }

}