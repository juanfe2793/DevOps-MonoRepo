# Variables Use to deploy Infrastructure on AWS for this template.
# AWs Region
variable "aws-region" {
  type        = string
  description = "AWS region"
}

# VPC Variables
variable "vpc-cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "vpc-name" {
  type        = string
  description = "VPC name"
}

variable "aws-availability-zones" {
  type        = list
  description = "AWS zones"
}

variable "public_subnet_cidr_blocks" {
  type = list
  description = " CIDR block for public subnets"

}

variable "private_subnet_cidr_blocks" {
  type = list
  description = "CIDR block for private subnets"

}

# Jenkins Variables
variable "jenkins-ami-id" {
  type        = string
  description = "EC2 AMI identifier"
}

variable "jenkins-instance-type" {
  type        = string
  description = "EC2 instance type"
}

variable "jenkins-key-name" {
  type        = string
  description = "EC2 ssh key name"
}

# Devops Application Variables

variable "ami_name_filter" {
   type = string
   description = "Filter to use to find the AMI by name"

   default = "devops-app-jgomez*"
}

variable "ami_owner" {
   description = "Filter for the AMI owner"
   default = "self"
}

# Devops database Variables

variable "db_username" {
   description = "The user name to RDS MySQL db"
   type = string
}

variable "db_password" {
   description = "The password to RDS MySQL db"
   type = string
}