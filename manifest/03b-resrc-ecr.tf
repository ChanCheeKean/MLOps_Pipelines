### create ecr image repo ###
resource "aws_ecr_repository" "repo" {
  for_each     = var.ecr_map
  name         = "${var.project_name}-${each.key}-${local.deploy-env}"
  force_delete = true
}