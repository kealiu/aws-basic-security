
variable "aws_config_bucket_name" {
    type = string
    description = "the bucket name of aws config"
}

variable "region" {
  type = string
  description = "the current region of aws"
}

variable "admin_email" {
  type = list(string)
  description = "the admin emails, prefer group email instead of personal ones"  
}

