variable "project_name" {
  description = "Name of project to be created"
  type        = string
  default     = "ml-infra-pipelines"
}

variable "region" {
  description = "Region in which AWS resources to be created"
  type        = string
  default     = "ap-southeast-1"
}

variable "model_package_group" {
  description = "Sagemaker Package GroupName"
  type        = string
  default     = "ml-infra-iris-predictor"
}

variable "ecr_map" {
  description = "Directory for each elastic registry"
  type        = map(string)
  default = {
    train = "./",
  }
}

variable "lambda_map" {
  description = "Directory for each lambda function"
  type        = map(string)
  default = {
    deploy = "../deploy",
    infer = "../inference",
  }
}

locals {
  # if workspace is default then env is dev
  deploy-env = terraform.workspace == "default" ? "dev" : terraform.workspace
}