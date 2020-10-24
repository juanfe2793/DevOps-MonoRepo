/**
 * Template develop by: Juan Felipe Gómez Manzanares. M. Sc.
 */

# Set a Provider
provider "aws" {
  region = var.aws-region
}

/**
 * #### VPC Configuration ####
*/

# Create a VPC
resource "aws_vpc" "devops-vpc" {
  cidr_block = var.vpc-cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc-name
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "devops-igw" {
  vpc_id = aws_vpc.devops-vpc.id
}

# Create an ElasticIP
resource "aws_eip" "nat-eip" {
  vpc = true

  tags = {
    Name = "IP for NAT gateway"
  }
}

# Create NAT
resource "aws_nat_gateway" "devops-nat" {

  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.devops-igw]
}

# Create public and private route

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.devops-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops-igw.id
  }

  tags = {
    Name = "PublicRoute"
  }
}

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.devops-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.devops-nat.id
  }

  tags = {
    Name = "PrivateRoute"
  }
}

# Create and associate public subnets with a route table
resource "aws_subnet" "public" {

  count = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.devops-vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.aws-availability-zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_route_table_association" "public" {

  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create and associate private subnets with a route table
resource "aws_subnet" "private" {

  count = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.devops-vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.aws-availability-zones[count.index]

  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_route_table_association" "private" {

  count = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

/**
 * #### IAM Roles Configuration ####
*/


# Role for Jenkins allow access EC2
resource "aws_iam_role" "role-jenkins" {
  name               = "role-for-Jenkins"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

# Role for App Instances
resource "aws_iam_role" "role-devops-app" {
  name               = "role-for-devops-app"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

# Associate Profile to EC2 Jenkins instance
resource "aws_iam_instance_profile" "EC2-profile-Jenkins" {
  name = "Profile-jenkins"
  role = aws_iam_role.role-jenkins.name
}

# Associate Profile to EC2 app instance
resource "aws_iam_instance_profile" "devops-app" {
  name = "Profile-devops-app"
  role = aws_iam_role.role-devops-app.name
}

# Policy for access to CodeCommit
resource "aws_iam_policy" "code-policy" {
  name   = "code-policy"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Effect": "Allow",
            "Action": [
                "codecommit:Get*",
                "codecommit:GitPull",
                "codecommit:List*"
            ],
            "Resource": "*"
       },
       {
            "Effect": "Allow",
            "NotAction": [
                "s3:DeleteBucket"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

# Policy for Jenkins
resource "aws_iam_policy" "jenkins-policy" {
  name   = "jenkins-policy"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:AttachVolume",
           "ec2:CreateVolume",
           "ec2:DeleteVolume",
           "ec2:CreateKeypair",
           "ec2:DeleteKeypair",
           "ec2:DescribeSubnets",
           "ec2:CreateSecurityGroup",
           "ec2:DeleteSecurityGroup",
           "ec2:AuthorizeSecurityGroupIngress",
           "ec2:CreateImage",
           "ec2:CopyImage",
           "ec2:RunInstances",
           "ec2:DescribeVolumes",
           "ec2:DetachVolume",
           "ec2:DescribeInstances",
           "ec2:CreateSnapshot",
           "ec2:DeleteSnapshot",
           "ec2:DescribeSnapshots",
           "ec2:DescribeImages",
           "ec2:RegisterImage",
           "ec2:CreateTags",
           "ec2:StopInstances",
           "ec2:TerminateInstances",
           "ec2:ModifyImageAttribute",
           "s3:*"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": "iam:PassRole",
         "Resource": ["${aws_iam_role.role-devops-app.arn}"]
}
    ]
}
EOF

}

# Attach Code policy to Jenkins and Dev-Ops app Roles.
resource "aws_iam_policy_attachment" "code" {
  name       = "code"
  policy_arn = aws_iam_policy.code-policy.arn
  roles = [
    aws_iam_role.role-jenkins.name,
    aws_iam_role.role-devops-app.name,
  ]
}

# Attach Jenkins policy to Jenkins Role.
resource "aws_iam_policy_attachment" "jenkins" {
  name       = "jenkins"
  policy_arn = aws_iam_policy.jenkins-policy.arn
  roles      = [aws_iam_role.role-jenkins.name]
}

/**
* ### Elastic Load Balancers Configuration ###
*/

# Create Sec. Group for app
resource "aws_security_group" "sg-devops-app-elb" {
  name        = "sec-group-devops-app-elb"
  description = "ELB security group for devops test application"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "5000"
    to_port     = "5000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sec-Group-devops-app-elb"
  }
}

# Creates Elastic Load Balancer
resource "aws_elb" "devops-app-elb" {

  name            = "devops-app-elb"
  security_groups = [aws_security_group.sg-devops-app-elb.id]
  subnets         = [aws_subnet.public[0].id]
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 2
  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5000/"
    interval            = 30
  }

  tags = {
    Name = "devops-app-elb"
  }
}

# Sec. Group for ELB app in production
resource "aws_security_group" "sg-devops-app-elb-prod" {
  name        = "sec-group-devops-app-elb-prod"
  description = "ELB security group for devops test app in production"
  vpc_id      = aws_vpc.devops-vpc.id
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "5000"
    to_port     = "5000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ELB production
resource "aws_elb" "devops-app-elb-prod" {

  name                        = "devops-app-elb-prod"
  security_groups             = [aws_security_group.sg-devops-app-elb-prod.id]
  subnets                     = [aws_subnet.public[0].id]
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 2
  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5000/"
    interval            = 30
  }
  tags = {
    Name = "devops-app-elb-prod"
  }
}

/**
* #### EC2 instances (jenkins and devops app) Configuration ###
*/

#Sec group for Jenkins Instance.
resource "aws_security_group" "sg-jenkins" {
  name        = "sec-group-jenkins"
  description = "ec2 instance security group for jenkins instance"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "5000"
    to_port     = "5000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Sec group for App Instance.
resource "aws_security_group" "sg-devops-app" {
  name        = "sec-group-devops-app"
  description = "ec2 instance security group for devops test aplication"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    from_port       = "80"
    to_port         = "80"
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-devops-app-elb.id, aws_security_group.sg-devops-app-elb-prod.id]
  }

  ingress {
    from_port       = "5000"
    to_port         = "5000"
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-devops-app-elb.id, aws_security_group.sg-devops-app-elb-prod.id]
  }

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-jenkins.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
/**
### Create Key Pair to Jenkins ###

#resource "tls_private_key" "jenkins-ci-key" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}

#resource "aws_key_pair" "generated_key" {
#  key_name   = var.jenkins-key-name
#  public_key = tls_private_key.jenkins-ci-key.public_key_openssh
#}
*/

/**
* ### Jenkins Instance Configuration ####
*/

resource "aws_instance" "ec2-jenkins" {

  ami                    = var.jenkins-ami-id
  instance_type          = var.jenkins-instance-type
  key_name               = var.jenkins-key-name
  vpc_security_group_ids = [aws_security_group.sg-jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.EC2-profile-Jenkins.id
  subnet_id              = aws_subnet.public[0].id
  tags = {
    Name = "jenkins ci"
  }
  user_data = file("../scripts/jenkins.sh")

  lifecycle { create_before_destroy = true }
}

resource "aws_eip" "ip-jenkins" {

  instance = aws_instance.ec2-jenkins.id
  vpc      = true

  tags = {
    Name = "IP Jenkins"
  }

}

/**
* ### instance to test ### 
*/

resource "aws_instance" "devops-app-test" {

  ami                    = data.aws_ami.devops-app-ami.id
  instance_type          = var.jenkins-instance-type
  key_name               = var.jenkins-key-name
  vpc_security_group_ids = [aws_security_group.sg-jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.EC2-profile-Jenkins.id
  subnet_id              = aws_subnet.public[0].id
  tags = {
    Name = "Devops-test"
  }
  user_data = file("../scripts/run-app.sh")

  lifecycle { create_before_destroy = true }
}

resource "aws_eip" "ip-devops" {

  instance = aws_instance.devops-app-test.id
  vpc      = true

  tags = {
    Name = "IP Devops test"
  }

}

/**
* #### Launch Configuration Template ####
*/

# Use AMI created with packer

data "aws_ami" "devops-app-ami" {
 most_recent      = true
 owners           = [var.ami_owner]
 
 filter {
   name   = "name"
   values = [var.ami_name_filter]
 }
 filter {
   name   = "root-device-type"
   values = ["ebs"]
 }
 filter {
   name   = "virtualization-type"
   values = ["hvm"]
 }
}

# launch configuration template
resource "aws_launch_configuration" "lconf-devops-app" {
  name                 = "devops_launch_config"
  image_id             = data.aws_ami.devops-app-ami.id
  instance_type        = var.jenkins-instance-type
  iam_instance_profile = aws_iam_instance_profile.devops-app.id
  security_groups      = [aws_security_group.sg-devops-app.id]
  user_data            = file("../scripts/run-app.sh")

}

/**
* Autoscaling Group Configurations
*/

# Auto-scaling group to blue group
resource "aws_autoscaling_group" "devops-app-blue" {

  name                 = "devops-app-blue"
  launch_configuration = aws_launch_configuration.lconf-devops-app.id
  vpc_zone_identifier  = [aws_subnet.private[0].id]
  min_size             = 1
  max_size             = 2
  load_balancers       = [aws_elb.devops-app-elb.id]
  tag {
    key                 = "AutoScaling-Name"
    value               = "devops-app-blue"
    propagate_at_launch = true
  }
}

# Attach Autoscaling group to ELB dev
resource "aws_autoscaling_attachment" "asg-attach-blue" {
  autoscaling_group_name = aws_autoscaling_group.devops-app-blue.id
  elb                    = aws_elb.devops-app-elb.id
}

# Auto-scaling group to green group
resource "aws_autoscaling_group" "devops-app-green" {

  name                 = "devops-app-green"
  launch_configuration = aws_launch_configuration.lconf-devops-app.id
  vpc_zone_identifier  = [aws_subnet.private[0].id]
  min_size             = 1
  max_size             = 2
  load_balancers       = [aws_elb.devops-app-elb-prod.id]
  tag {
    key                 = "AutoScaling-Name"
    value               = "devops-app-green"
    propagate_at_launch = true
  }
}

# Attach Autoscaling group to ELB prod
resource "aws_autoscaling_attachment" "asg_attach-prod" {
  autoscaling_group_name = aws_autoscaling_group.devops-app-green.id
  elb                    = aws_elb.devops-app-elb-prod.id
}

/**
* Buckets S3 configuration
*/

# Bucket S3 to save artifacts 

resource "aws_s3_bucket" "bucket-devops" {
  bucket = "devops-app-artifacts-jgomez"
  acl    = "private"
  force_destroy = true
  tags = {
    Name        = "Bucket Artifacts"
  }
}

# Bucket S3 to Cloudtrail Logs

resource "aws_s3_bucket" "devops-app-trail-jgomez" {
  bucket = "devops-app-trail-jgomez"
  acl    = "private"
  force_destroy = true

  tags = {
    Name        = "Bucket Logs"
    Environment = "Dev"
  }
}

/**
* ### Create Database RDS to save data ###
*/


 resource "aws_db_instance" "devops-rds" {
   allocated_storage    = 20
   storage_type         = "gp2"
   engine               = "mysql"
   engine_version       = "5.7"
   instance_class       = "db.t2.micro"
   name                 = "devopsdbjgomez"
   username             = var.db_username
   password             = var.db_password
   parameter_group_name = "default.mysql5.7"
}

/**
*  ### Configuration Metrics (Cloudwatch) ###
*/

# Cloudwatch dashboard
resource "aws_cloudwatch_dashboard" "cw-jenkins" {
  dashboard_name = "Jenkins-CPU"

  dashboard_body = <<EOF
 {
   "widgets": [
       {
          "type":"metric",
          "x":0,
          "y":0,
          "width":12,
          "height":6,
          "properties":{
             "metrics":[
                [
                   "AWS/EC2",
                   "CPUUtilization",
                   "InstanceId",
                   "aws_instance.ec2-jenkins.id"
                ]
             ],
             "period":300,
             "stat":"Average",
             "region":"us-east-1",
             "title":"EC2 Jenkins CPU"
          }
       },
       {
          "type":"text",
          "x":0,
          "y":7,
          "width":3,
          "height":3,
          "properties":{
             "markdown":"CPU Jenkins"
          }
       }
   ]
 }
 EOF
}

# Alarmas Cloudwatch Autoscaling Blue Group 

resource "aws_autoscaling_policy" "devops-blue-policy" {
  name                   = "devops-blue-policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.devops-app-blue.name
}

resource "aws_cloudwatch_metric_alarm" "devops-blue-alarm" {
  alarm_name          = "devops-blue-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.devops-app-blue.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.devops-blue-policy.arn]
}

# Alarmas Cloudwatch Autoscaling Green Group

resource "aws_autoscaling_policy" "devops-green-policy" {
  name                   = "devops-green-policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.devops-app-green.name
}

resource "aws_cloudwatch_metric_alarm" "devops-green-alarm" {
  alarm_name          = "devops-green-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.devops-app-green.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.devops-green-policy.arn]
}

/**
 * CloudTrail resource for monitoring all services
 */


# resource "aws_cloudtrail" "master_cloudtrail" {
  
#   name                          = master-cloudtrail-devops-app
#   s3_bucket_name                = aws_s3_bucket.devops-app-trail-jgomez.id
#   s3_key_prefix                 = "cloudtrail"
#   include_global_service_events = true
#   enable_log_file_validation    = true
#   enable_logging                = true
#   is_multi_region_trail         = true

#   tags {
#     name = "Master Cloudtrail"
#   }
# }

