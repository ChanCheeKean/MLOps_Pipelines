### create new bucket ###
resource "aws_s3_bucket" "ml_pipelines_bucket" {
  bucket = "${var.project_name}-${local.deploy-env}"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}

### transfer a temporary data into the bucket ###
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.ml_pipelines_bucket.bucket
  source = "../dataset/iris.csv"
  key    = "/sample/training/iris.csv"
}
