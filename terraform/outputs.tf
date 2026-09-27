output "management_public_ip" {
  value = aws_instance.management.public_ip
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker1_public_ip" {
  value = aws_instance.worker1.public_ip
}

output "worker2_public_ip" {
  value = aws_instance.worker2.public_ip
}