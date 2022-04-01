data "template_file" "jcasc_config" {
    template = "${file("${path.module}/templates/jcasc-default-config.tmpl")}"
    vars = {
        jenkins_service_url = "http://${kubernetes_service.jenkins-service.spec.0.cluster_ip}:${kubernetes_service.jenkins-service.spec.0.port.0.port}"
        jenkins_admin_name = var.jenkins_admin_name
    }
}