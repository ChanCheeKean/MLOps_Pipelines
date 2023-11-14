output "ml_infra_train_repo_url" {
  value = aws_codecommit_repository.train_repo.clone_url_http
}

output "codebuild_project_arn" {
  value = aws_codebuild_project.train.arn
}

output "code_pipeline_name" {
  value = aws_codepipeline.train.name
}

output "ecr_images" {
  description = "List of Container Images Created"
  value       = [for ele in aws_ecr_repository.repo : ele.repository_url]
}

output "lambda_function_name" {
  description = "Role name for sagemaker execution"
  value       = [for ele in aws_lambda_function.lambda_function : ele.function_name]
}

output "api_base_url" {
  description = "Url of API gateway to trigger Lambda Function"
  value       = aws_api_gateway_deployment.apideploy.invoke_url
}

output "sagemaker_role" {
  description = "Role name for sagemaker execution"
  value       = aws_iam_role.sagemaker_role.name
}