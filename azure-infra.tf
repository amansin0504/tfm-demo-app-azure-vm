#Create VPC network (if you change cidr block make sure you update resolver in nginx conf file)
resource "aws_vpc" "safe-vpc-network" {
  cidr_block    = "10.0.0.0/16"
  tags = {
    Name = "microservices-ec2-vpc"
  }
}
resource "aws_flow_log" "cswflowlogs" {
  log_destination      = var.csws3arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.safe-vpc-network.id
  log_format = "$${account-id} $${action} $${bytes} $${dstaddr} $${dstport} $${end} $${instance-id} $${interface-id} $${log-status} $${packets} $${pkt-dstaddr} $${pkt-srcaddr} $${protocol} $${srcaddr} $${srcport} $${start} $${subnet-id} $${tcp-flags} $${type} $${version} $${vpc-id} $${flow-direction}"
}

#Create subnets in VPC network
resource "aws_subnet" "websubnet1" {
  vpc_id            = aws_vpc.safe-vpc-network.id
  availability_zone = var.az1
  cidr_block        = "10.0.1.0/24"
}
resource "aws_subnet" "websubnet2" {
  vpc_id            = aws_vpc.safe-vpc-network.id
  availability_zone = var.az2
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "appsubnet1" {
  vpc_id            = aws_vpc.safe-vpc-network.id
  availability_zone = var.az1
  cidr_block        = "10.0.3.0/24"
}
resource "aws_subnet" "appsubnet2" {
  vpc_id            = aws_vpc.safe-vpc-network.id
  availability_zone = var.az2
  cidr_block        = "10.0.4.0/24"
}

resource "aws_subnet" "dbsubnet1" {
  vpc_id            = aws_vpc.safe-vpc-network.id
  availability_zone = var.az1
  cidr_block        = "10.0.5.0/24"
}
resource "aws_subnet" "dbsubnet2" {
  vpc_id            = aws_vpc.safe-vpc-network.id
  availability_zone = var.az2
  cidr_block        = "10.0.6.0/24"
}

#Create internet gateway
resource "aws_internet_gateway" "internetgateway" {
  vpc_id = aws_vpc.safe-vpc-network.id
  tags = {
    Name = "SafeIGW"
  }
}

#Create Nat gateway
resource "aws_eip" "nateip1" {
  vpc = true
}
resource "aws_nat_gateway" "natgateway1" {
  allocation_id = aws_eip.nateip1.id
  subnet_id     = aws_subnet.websubnet1.id
  tags = {
    Name = "safeNATGW"
  }
  depends_on = [aws_internet_gateway.internetgateway]
}
resource "aws_eip" "nateip2" {
  vpc = true
}
resource "aws_nat_gateway" "natgateway2" {
  allocation_id = aws_eip.nateip2.id
  subnet_id     = aws_subnet.websubnet2.id
  tags = {
    Name = "safeNATGW"
  }
  depends_on = [aws_internet_gateway.internetgateway]
}

#Route tables
resource "aws_route_table" "webRT" {
  vpc_id = aws_vpc.safe-vpc-network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgateway.id
  }
  tags = {
    Name = "webRT"
  }
}
resource "aws_route_table_association" "webRTtowebsubnet1" {
  subnet_id      = aws_subnet.websubnet1.id
  route_table_id = aws_route_table.webRT.id
}
resource "aws_route_table_association" "webRTtowebsubnet2" {
  subnet_id      = aws_subnet.websubnet2.id
  route_table_id = aws_route_table.webRT.id
}

resource "aws_route_table" "appRT1" {
  vpc_id = aws_vpc.safe-vpc-network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway1.id
  }
  tags = {
    Name = "appRT1"
  }
}
resource "aws_route_table_association" "appRT1toappsubnet1" {
  subnet_id      = aws_subnet.appsubnet1.id
  route_table_id = aws_route_table.appRT1.id
}

resource "aws_route_table" "appRT2" {
  vpc_id = aws_vpc.safe-vpc-network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway2.id
  }
  tags = {
    Name = "appRT2"
  }
}
resource "aws_route_table_association" "appRT2toappsubnet2" {
  subnet_id      = aws_subnet.appsubnet2.id
  route_table_id = aws_route_table.appRT2.id
}

resource "aws_route_table" "dbRT1" {
  vpc_id = aws_vpc.safe-vpc-network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway1.id
  }
  tags = {
    Name = "dbRT1"
  }
}
resource "aws_route_table_association" "dbRT1todbsubnet1" {
  subnet_id      = aws_subnet.dbsubnet1.id
  route_table_id = aws_route_table.dbRT1.id
}

resource "aws_route_table" "dbRT2" {
  vpc_id = aws_vpc.safe-vpc-network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway2.id
  }
  tags = {
    Name = "dbRT2"
  }
}
resource "aws_route_table_association" "dbRT2todbsubnet2" {
  subnet_id      = aws_subnet.dbsubnet2.id
  route_table_id = aws_route_table.dbRT2.id
}

resource "aws_security_group" "allow_safe_access" {
  name        = "allow_safe_access"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.safe-vpc-network.id

  ingress {
    description      = "all access"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    description      = "all access"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_all_access"
  }
}

#Create Frontend Server
data "template_file" "frontendinit" {
  template = file("scripts/frontend.sh")
}
data "template_cloudinit_config" "frontendconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.frontendinit.rendered
  }
}
resource "aws_network_interface" "frontend" {
  subnet_id   = aws_subnet.websubnet1.id
  private_ips = ["10.0.1.10"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "frontend"
  }
}
resource "aws_instance" "frontend" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.frontendconfig.rendered
   network_interface {
    network_interface_id = aws_network_interface.frontend.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "frontend"
  }
}
resource "aws_eip" "frontendeip" {
  depends_on = [aws_internet_gateway.internetgateway]
  instance = aws_instance.frontend.id
  vpc      = true
}
resource "aws_eip_association" "frontendeipassociation" {
  instance_id   = aws_instance.frontend.id
  allocation_id = aws_eip.frontendeip.id
}


#Create checkout Server
data "template_file" "checkoutinit" {
  template = file("scripts/checkout.sh")
}
data "template_cloudinit_config" "checkoutconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.checkoutinit.rendered
  }
}
resource "aws_network_interface" "checkout" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.10"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "checkout"
  }
}
resource "aws_instance" "checkout" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.checkoutconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.checkout.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "checkout"
  }
}

#Create ad Server
data "template_file" "adinit" {
  template = file("scripts/ad.sh")
}
data "template_cloudinit_config" "adconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.adinit.rendered
  }
}
resource "aws_network_interface" "ad" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.11"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "ad"
  }
}
resource "aws_instance" "ad" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.adconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.ad.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "ad"
  }
}
#Create recommendation Server
data "template_file" "recommendationinit" {
  template = file("scripts/recommendation.sh")
}
data "template_cloudinit_config" "recommendationconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.recommendationinit.rendered
  }
}
resource "aws_network_interface" "recommendation" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.12"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "recommendation"
  }
}
resource "aws_instance" "recommendation" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.recommendationconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.recommendation.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "recommendation"
  }
}
#Create payment Server
data "template_file" "paymentinit" {
  template = file("scripts/payment.sh")
}
data "template_cloudinit_config" "paymentconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.paymentinit.rendered
  }
}
resource "aws_network_interface" "payment" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.13"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "payment"
  }
}
resource "aws_instance" "payment" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.paymentconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.payment.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "payment"
  }
}
#Create emails Server
data "template_file" "emailsinit" {
  template = file("scripts/emails.sh")
}
data "template_cloudinit_config" "emailsconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.emailsinit.rendered
  }
}
resource "aws_network_interface" "emails" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.14"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "emails"
  }
}
resource "aws_instance" "emails" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.emailsconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.emails.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "emails"
  }
}
#Create productcatalog Server
data "template_file" "productcataloginit" {
  template = file("scripts/productcatalog.sh")
}
data "template_cloudinit_config" "productcatalogconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.productcataloginit.rendered
  }
}
resource "aws_network_interface" "productcatalog" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.15"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "productcatalog"
  }
}
resource "aws_instance" "productcatalog" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.productcatalogconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.productcatalog.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "productcatalog"
  }
}
#Create shipping Server
data "template_file" "shippinginit" {
  template = file("scripts/shipping.sh")
}
data "template_cloudinit_config" "shippingconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.shippinginit.rendered
  }
}
resource "aws_network_interface" "shipping" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.16"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "shipping"
  }
}
resource "aws_instance" "shipping" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.shippingconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.shipping.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "shipping"
  }
}
#Create currency Server
data "template_file" "currencyinit" {
  template = file("scripts/currency.sh")
}
data "template_cloudinit_config" "currencyconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.currencyinit.rendered
  }
}
resource "aws_network_interface" "currency" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.17"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "currency"
  }
}
resource "aws_instance" "currency" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.currencyconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.currency.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "currency"
  }
}
#Create cart Server
data "template_file" "cartinit" {
  template = file("scripts/carts.sh")
}
data "template_cloudinit_config" "cartconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.cartinit.rendered
  }
}
resource "aws_network_interface" "cart" {
  subnet_id   = aws_subnet.appsubnet1.id
  private_ips = ["10.0.3.18"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "cart"
  }
}
resource "aws_instance" "carts" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.cartconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.cart.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "cart"
  }
}
#Create redis Server
data "template_file" "redisinit" {
  template = file("scripts/redis.sh")
}
data "template_cloudinit_config" "redisconfig" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "appconfig.cfg"
    content_type = "text/x-shellscript"
    content      = data.template_file.redisinit.rendered
  }
}
resource "aws_network_interface" "redis" {
  subnet_id   = aws_subnet.dbsubnet1.id
  private_ips = ["10.0.5.10"]
  security_groups   = [aws_security_group.allow_safe_access.id]
  tags = {
    Name = "redis"
  }
}
resource "aws_instance" "redis" {
   instance_type = "t2.micro"
   ami = var.images[var.region]
   user_data_base64  = data.template_cloudinit_config.redisconfig.rendered
   depends_on = [aws_nat_gateway.natgateway1,aws_nat_gateway.natgateway2]
   network_interface {
    network_interface_id = aws_network_interface.redis.id
    device_index         = 0
  }
  key_name = var.keyname
  tags = {
    Name = "redis"
  }
}
