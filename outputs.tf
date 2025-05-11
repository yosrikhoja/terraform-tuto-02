output public_ip {
    description = "Public IP of the instance"
    sensitive   = false
    value       = aws_instance.example.public_ip
}
