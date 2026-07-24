output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_url" {
  value = "https://${var.domain_name}"
}

output "ec2_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Not stable across stop/start — no Elastic IP is attached."
}

output "ecr_backend_uri" {
  value = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_uri" {
  value = aws_ecr_repository.frontend.repository_url
}
