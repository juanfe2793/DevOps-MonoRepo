aws-region = "us-east-1"
vpc-cidr = "10.0.0.0/16"
vpc-name = "devops-test"
aws-availability-zones = ["us-east-1a", "us-east-1b"]
public_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.2.0/24"]
private_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.3.0/24"]
jenkins-ami-id = "ami-0b69ea66ff7391e80"
jenkins-instance-type = "t2.micro"
jenkins-key-name = "devops-app"
ami_name_filter = "devops-app-jgomez*"
db_username = "devopsuser"
db_password = "password123!"