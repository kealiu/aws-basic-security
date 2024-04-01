provider "aws" {
  region = "us-east-1"
}

variable "admin_email" {
  type = list(string)
  description = "the admin emails, prefer group email instead of personal ones"  
}

variable "random_str" {
  type = string
  description = "just a random, lower, alphanum string, for unique this apply"
}

variable "aws_config_bucket_name" {
  type = string
  description = "the aws config bucket name"
}