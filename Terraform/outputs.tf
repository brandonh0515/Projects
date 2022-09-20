output "AnsibleMaster_IP" {
  value = aws_instance.AnsibleMaster.public_ip
}
