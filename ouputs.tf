// Specify output to access jenkins password quickly

output "jenkins_password" {
    sensitive = true
    value  = random_password.password.0.result
}