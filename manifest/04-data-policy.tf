data "aws_caller_identity" "current" {}

### general: ec2, cloudwatch, s3, event ###
data "aws_iam_policy_document" "general_policy" {

  # iam
  statement {
    effect = "Allow"
    actions = ["iam:*"]
    resources = ["*"]
  }

  # cloudwatch log group
  statement {
    effect = "Allow"
    actions = ["logs:*"]
    resources = ["*"]
  }

  # ec2
  statement {
    effect = "Allow"
    actions = ["ec2:*", "sagemaker:*"]
    resources = ["*"]
  }

  # s3 and codepipeline
  statement {
    effect = "Allow"
    actions = ["s3:*", "codecommit:*", "codebuild:*"]
    resources = ["*"]
  }

  # ecr
  statement {
    effect  = "Allow"
    actions = ["ecr:*"]
    resources = ["*"]
  }
}


### code build and event ###
data "aws_iam_policy_document" "code_build_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com", "events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


### code pipeline ###
data "aws_iam_policy_document" "code_pipeline_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

### sagemaker ###
data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "sagemaker_policy" {
  # s3
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }

  # ecr
  statement {
    effect  = "Allow"
    actions = ["ecr:*"]
    resources = [
      "*"
    ]
  }

  # sagemaker
  statement {
    effect  = "Allow"
    actions = ["sagemaker:*"]
    resources = ["*"]
  }

  # cloudwatch log group
  statement {
    effect = "Allow"
    actions = ["logs:*",]
    resources = ["*"]
  }

  # lambda
  statement {
    effect  = "Allow"
    actions = ["lambda:*"]
    resources = [
      "*"
    ]
  }
}

### sagemaker package group ###
data "aws_iam_policy_document" "package_group_policy" {
  statement {
    sid       = "AddPermModelPackageGroup"
    actions   = ["sagemaker:DescribeModelPackage", "sagemaker:ListModelPackages"]
    resources = [aws_sagemaker_model_package_group.example.arn]
    principals {
      identifiers = [data.aws_caller_identity.current.account_id]
      type        = "AWS"
    }
  }
}

### lambda ###
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

