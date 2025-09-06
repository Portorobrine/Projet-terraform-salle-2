output "bastion_public_ip" {
    description = "Public IP address of the bastion host"
    value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
    description = "Private IP address of the bastion host"
    value       = aws_instance.bastion.private_ip
}

output "bastion_instance_id" {
    description = "ID of the bastion instance"
    value       = aws_instance.bastion.id
}

output "app_instance_public_ips" {
    description = "Public IP addresses of the app instances"
    value       = aws_instance.webapp[*].public_ip
}

output "app_instance_private_ips" {
    description = "Private IP addresses of the app instances"
    value       = aws_instance.webapp[*].private_ip
}

output "app_instance_ids" {
    description = "IDs of the app instances"
    value       = aws_instance.webapp[*].id
}