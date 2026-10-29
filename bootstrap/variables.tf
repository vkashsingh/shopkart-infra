##
# Input Variables
# Declares configurable inputs for the bootstrap module, including target AWS
# region where the state S3 bucket is hosted.
##

variable "region" {
  description = "AWS region for the Terraform state S3 bucket"
  type        = string
  default     = "ap-southeast-2"
}
