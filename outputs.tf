
output "alb_dns_name" {
    description = "DNS name of the ALB"
    sensitive   = false
    value       = aws_lb.example.dns_name
  
}