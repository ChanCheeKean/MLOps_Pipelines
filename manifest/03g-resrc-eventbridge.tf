### event trigger and target: codecommit --> codebuild ####

resource "aws_cloudwatch_event_rule" "sagemaker_event_rule" {
  name          = "${var.project_name}-${local.deploy-env}-sagemaker-event"
  description   = "Rule to trigger Endpoind Deployment"
  is_enabled    = true
  event_pattern = <<PATTERN
    {
        "source": ["aws.sagemaker"],
        "detail-type": ["SageMaker Model State Change"]
        "resources": ${aws_sagemaker_model_package_group.sagemaker_group.arn},
        "detail": {
            "version": "0",
            "eventName": ["ModelApprovalStatusChange"],
        }
    }
  PATTERN
}

resource "aws_cloudwatch_event_target" "codebuild_target" {
  rule      = aws_cloudwatch_event_rule.sagemaker_event_rule.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.lambda_func["deploy"].arn
  role_arn  = aws_iam_role.lambda_role.arn
}
