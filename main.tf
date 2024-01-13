resource "aws_vpc" "main" {
     cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "${local.project_name}-${local.env}-vpc"
  }
  
}

resource "aws_subnet" "public" {
count=length(var.public_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch=true
  tags = {
    Name = "${local.project_name}-${local.env}-public-${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
count=length(var.private_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets[count.index]
    availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.project_name}-${local.env}-private-${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "database" {
count=length(var.database_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnets[count.index]
    availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.project_name}-${local.env}-database-${var.availability_zones[count.index]}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-${local.env}-igw"
  }
}


resource "aws_eip" "main" {
  domain   = "vpc"
}



resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.project_name}-${local.env}-ngw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-${local.env}-public-route"
  }
}
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {

  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-${local.env}-private-route"
  }
}
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.ngw.id
}

resource "aws_route_table_association" "private" {

  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-${local.env}-database-route"
  }
}
resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.ngw.id
}

resource "aws_route_table_association" "database" {

  subnet_id      = aws_subnet.database[0].id
  route_table_id = aws_route_table.database.id
}
resource "aws_db_subnet_group" "default" {
  name       = "database-connect-aws"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "database-connect-aws"
  }
}