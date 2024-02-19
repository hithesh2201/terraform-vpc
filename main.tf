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
  gateway_id = data.aws_internet_gateway.default.id
}

resource "aws_route_table_association" "public" {

  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "vpn_default_public" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "vpn_default_public_route"
  }
}
resource "aws_route" "vpn_default" {
  route_table_id            = aws_route_table.vpn_default_public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =data.aws_internet_gateway.default.id.vpc-gw.id
}

resource "aws_route_table_association" "vpn_default" {

  subnet_id      = data.aws_subnet.selected.id
  route_table_id = aws_route_table.vpn_default_public.id
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

  subnet_id     = aws_subnet.database[0].id
  route_table_id = aws_route_table.database.id
}
resource "aws_db_subnet_group" "default" {
  name       = "database-connect-aws"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "database-connect-aws"
  }
}


# Define VPC peering connection
resource "aws_vpc_peering_connection" "peering_connection" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = data.aws_vpc.default.id
  auto_accept   = true  # You can set this to false if you want to manually accept the peering connection
}

# Define route in VPC 1 to route traffic to VPC 2 through the peering connection
resource "aws_route" "route_to_vpc2" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
}

resource "aws_route" "route_to_private_vpc2" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
}


resource "aws_route" "route_to_database_vpc2" {
  route_table_id         = aws_route_table.database.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
}


# Define route in VPC 2 to route traffic to VPC 1 through the peering connection
resource "aws_route" "route_to_vpc1" {
  route_table_id         = aws_route_table.vpn_default_public.id
  destination_cidr_block = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
}
