
# create cloudwatch synthetic
resource "aws_synthetics_canary" "cloudwatch_canary" {
  name                  = "${var.project_name}-${local.deploy-env}-endpoint"
  artifact_s3_location  = "${aws_s3_bucket.ml_pipelines_bucket.bucket}/synthethic/"
  execution_role_arn    = aws_iam_role.sagemaker_role.arn 
  handler              = "evaluate.handler"
  zip_file             = "synthethic/cloudwatch_synthethic.zip"
  runtime_version      = "1.0"

  # Define the canary script
  schedule {
    expression = "rate(120 minutes)"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm" {
  alarm_name                = "${var.project_name}-${local.deploy-env}-endpoint"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  metric_name               = "SuccessPercent"
  namespace                 = "CloudWatchSynthetics "
  period                    = 300
  statistic                 = "Average"
  threshold                 = 60
  alarm_actions = ["arn:aws:sns:us-west-2:123456789012:your-sns-topic"]
}

resource "aws_sns_topic" "sns_topic" {
  name = "${var.project_name}-${local.deploy-env}-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  # TODO: replace with email
  endpoint  = "zekinchan@gmail.com" 
}