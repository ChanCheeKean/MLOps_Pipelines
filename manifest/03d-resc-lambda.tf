data "aws_caller_identity" "current" {}

### create iam role ###
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${local.deploy-env}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.sagemaker_policy.json
}

### create ecr for each lambda images
resource "aws_ecr_repository" "lambda_repo" {
  for_each     = var.lambda_map
  name         = "${var.project_name}-${each.key}-${local.deploy-env}"
  force_delete = true
}

### local provisioner to run Docker File
resource "null_resource" "docker_image" {
  for_each = var.lambda_map

  # trigger by main.py and dockerfile
  triggers = {
    # always-update = timestamp()
    python_file = md5(file("${each.value}/main.py"))
    docker_file = md5(file("${each.value}/Dockerfile"))
  }

  provisioner "local-exec" {
    command = <<-EOF
        aws ecr get-login-password --region ${var.region} | && \
        docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com && \
        cd ${each.value} && \
        docker build -t ${aws_ecr_repository.repo["${each.key}"].repository_url}:latest -f ${each.value}/Dockerfile . && docker push ${aws_ecr_repository.repo["${each.key}"].repository_url}:latest
       EOF
  }
}

### extract id of each image in ECR
data "aws_ecr_image" "container_image" {
  for_each        = var.lambda_map
  depends_on      = [null_resource.docker_image]
  repository_name = "${var.project_name}-${each.key}-${local.deploy-env}"
  image_tag       = "latest"
}

### create lambda function
resource "aws_lambda_function" "lambda_func" {
  for_each = var.lambda_map
  depends_on = [
    null_resource.docker_image
  ]

  function_name = "${var.project_name}-${each.key}-${local.deploy-env}"
  role          = aws_iam_role.lambda_role.arn
  image_uri     = "${aws_ecr_repository.repo["${each.key}"].repository_url}@${data.aws_ecr_image.container_image["${each.key}"].id}"
  package_type  = "Image"
  timeout       = 300
  memory_size   = 2048
}

