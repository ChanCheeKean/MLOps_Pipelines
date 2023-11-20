### create iam role for sagemaker ###
resource "aws_iam_role" "sagemaker_role" {
  name               = "${var.project_name}-${local.deploy-env}-sagemaker"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy" "sagemaker_role_policy" {
  role   = aws_iam_role.sagemaker_role.name
  policy = data.aws_iam_policy_document.sagemaker_policy.json
}

### sagmaker package group ###
resource "aws_sagemaker_model_package_group" "sagemaker_group" {
  model_package_group_name = "${var.project_name}-${local.deploy-env}-packagegroup"
}

resource "aws_sagemaker_model_package_group_policy" "sagemaker_policy" {
  model_package_group_name = aws_sagemaker_model_package_group.sagemaker_group.model_package_group_name
  resource_policy          = jsonencode(jsondecode(data.package_group_policy.example.json))
}