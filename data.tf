data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
}
