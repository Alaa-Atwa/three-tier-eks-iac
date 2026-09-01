# vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # required for EKS nodes to resolve AWS service endpoints by hostname

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# IGW 
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# public subnet
# public subnet auto-assigns a public IP to anything launched here
# combined with the route table below sending 0.0.0.0/0 to the IGW. 
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  # map_public_ip_on_launch = true is what actually makes this a "public"

  tags = {
    Name                     = "${var.project_name}-${var.environment}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb" = "1"
    # This tag is a must for the AWS Load Balancer Controlle reads it to auto-discover which subnets to placeinternet-facing ALBs in.
  }
}

# private subnets (for eks worker nodes)
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  # no map_public_ip_on_launch here 

  tags = {
    Name                              = "${var.project_name}-${var.environment}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
    # Equivalent auto-discovery tag, but for internal load balancers.
  }
}

# NAT gateaway
# A NAT Gateway needs its own Elastic IP, and must physically sit in a PUBLIC subnet 
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.azs) # one for low cost, in production use more 
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.main]
}

# roue tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

#  A subnet is public specifically because its associated route table sends 0.0.0.0/0 (everything) to the IGW.
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associates each public subnet with the public route table.
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# private routing table
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.azs)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index}"
  }
}

resource "aws_route" "private_nat_access" {
  count                  = var.single_nat_gateway ? 1 : length(var.azs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
  # for routing more than nat gateway (if i added more than one)
}