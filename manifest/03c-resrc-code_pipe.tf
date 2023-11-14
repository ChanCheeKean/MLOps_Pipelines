### create ecr repository ###
resource "aws_codecommit_repository" "train_repo" {
  repository_name = "${var.project_name}-${local.deploy-env}-train"
  lifecycle {
    prevent_destroy = false
  }
}


### create iam role ###
resource "aws_iam_role" "code_build_role" {
  name               = "${var.project_name}-${local.deploy-env}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.code_build_assume_role.json
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy" "code_build_role_policy" {
  role   = aws_iam_role.code_build_role.name
  policy = data.aws_iam_policy_document.general_policy.json
}

resource "aws_iam_role_policy_attachment" "code_build_policy" {
  role       = aws_iam_role.code_build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}


### create codebuild training ###
resource "aws_codebuild_project" "train" {
  name          = "${var.project_name}-${local.deploy-env}-train"
  description   = "Code build for training"
  build_timeout = 5
  service_role  = aws_iam_role.code_build_role.arn

  lifecycle {
    prevent_destroy = false
  }

  artifacts {
    type     = "S3"
    name     = "artefact"
    location = aws_s3_bucket.ml_pipelines_bucket.bucket
    path     = "codebuild/"
  }

  source {
    type                = "CODECOMMIT"
    location            = aws_codecommit_repository.train_repo.clone_url_http
    git_clone_depth     = 1
    buildspec           = "train/buildspec.yml"
    report_build_status = true
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "${var.project_name}-${local.deploy-env}-train"
      # stream_name = "log-stream"
    }
  }

}


### Create CodePipeline ###
resource "aws_iam_role" "code_pipeline_role" {
  name               = "${var.project_name}-${local.deploy-env}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.code_pipeline_assume_role.json
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy" "code_pipeline_role_policy" {
  role   = aws_iam_role.code_pipeline_role.name
  policy = data.aws_iam_policy_document.general_policy.json
}

resource "aws_iam_role_policy_attachment" "code_pipeline_policy" {
  role       = aws_iam_role.code_pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

resource "aws_codepipeline" "train" {
  name     = "${var.project_name}-${local.deploy-env}-train-pipeline"
  role_arn = aws_iam_role.code_pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.ml_pipelines_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = aws_codecommit_repository.train_repo.repository_name
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.train.name
      }
    }
  }
}