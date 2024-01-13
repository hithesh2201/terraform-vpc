resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${local.project_name}/${local.env}/vpc_id"
  type  = "String"
  value = aws_vpc.main.id
}