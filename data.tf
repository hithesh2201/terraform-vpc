data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
}


data "aws_ssm_parameter" "default_igw_id" {
  name = "/${local.project_name}/default-igw"
}
