### Output information once finish the deploy
output "VPC-ID" {
  value = "${aws_vpc.devops-vpc.id}"
}
output "PUBLIC-SUBNET-ID" {
  value       = aws_subnet.public.*.id
  description = "List of public subnet IDs"
}
output "PRIVATE-SUBNET-ID" {
  value       = aws_subnet.private.*.id
  description = "List of public subnet IDs"
}
output "JENKINS-EIP" {
  value = aws_eip.ip-jenkins.*.public_ip
}
output "JENKINS-DNS" {
  value = aws_instance.ec2-jenkins.*.public_dns
}

output "ELB-URI-BLUE" {
  value = "${aws_elb.devops-app-elb.*.dns_name}"
}

output "devops-app-secgroup" {
  value = "${aws_security_group.sg-devops-app.id}" 
}

output "ELB-URI-GREEN" {
value = "${aws_elb.devops-app-elb-prod.*.dns_name}"
}

