#Create Azure Resource Group
resource "azurerm_resource_group" "microservicesdemorg" {
    name     = "MicroservicesDemoRG"
    location = var.location.value
}

#Create subnets in VNET network (if you change cidr block make sure you update resolver in nginx conf file)
resource "azurerm_virtual_network" "demovnet" {
    name                = "demovnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location.value
    resource_group_name = azurerm_resource_group.microservicesdemorg.name
}
resource "azurerm_subnet" "websubnet1" {
    name                 = "websubnet1"
    resource_group_name  = azurerm_resource_group.microservicesdemorg.name
    virtual_network_name = azurerm_virtual_network.demovnet.name
    address_prefixes       = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "websubnet2" {
    name                 = "websubnet2"
    resource_group_name  = azurerm_resource_group.microservicesdemorg.name
    virtual_network_name = azurerm_virtual_network.demovnet.name
    address_prefixes       = ["10.0.2.0/24"]
}
resource "azurerm_subnet" "appsubnet1" {
    name                 = "appsubnet1"
    resource_group_name  = azurerm_resource_group.microservicesdemorg.name
    virtual_network_name = azurerm_virtual_network.demovnet.name
    address_prefixes       = ["10.0.3.0/24"]
}
resource "azurerm_subnet" "appsubnet2" {
    name                 = "appsubnet2"
    resource_group_name  = azurerm_resource_group.microservicesdemorg.name
    virtual_network_name = azurerm_virtual_network.demovnet.name
    address_prefixes       = ["10.0.4.0/24"]
}
resource "azurerm_subnet" "dbsubnet1" {
    name                 = "dbsubnet1"
    resource_group_name  = azurerm_resource_group.microservicesdemorg.name
    virtual_network_name = azurerm_virtual_network.demovnet.name
    address_prefixes       = ["10.0.5.0/24"]
}
resource "azurerm_subnet" "dbsubnet2" {
    name                 = "dbsubnet2"
    resource_group_name  = azurerm_resource_group.microservicesdemorg.name
    virtual_network_name = azurerm_virtual_network.demovnet.name
    address_prefixes       = ["10.0.6.0/24"]
}

# Create an SSH key
resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "cswdemonsg" {
    name                = "cswdemonsg"
    location            = var.location.value
    resource_group_name = azurerm_resource_group.microservicesdemorg.name

    security_rule {
        name                       = "AllInbound"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "AllOutbound"
        priority                   = 1002
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create Network watcher - this is required if NW is not present, will also need ngs update below with watcher name and rg
#resource "azurerm_network_watcher" "cswwatcher" {
#  name                = "cswwatcher"
#  location            = azurerm_resource_group.microservicesdemorg.location
#  resource_group_name = azurerm_resource_group.microservicesdemorg.name
#}

# Create storage account
resource "azurerm_storage_account" "amansin3cswflowstorage" {
  name                = "amansin3cswflowstorage"
  resource_group_name = azurerm_resource_group.microservicesdemorg.name
  location            = azurerm_resource_group.microservicesdemorg.location

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

# Configure nsg to user network watcher and store logs in storage account
resource "azurerm_network_watcher_flow_log" "cswnsgflowwatcher" {
  network_watcher_name = var.watchername.value
  resource_group_name  = var.watcherrg.value
  name                 = "csw-log"

  network_security_group_id = azurerm_network_security_group.cswdemonsg.id
  storage_account_id        = azurerm_storage_account.amansin3cswflowstorage.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 15
  }
}

# Create virtual machines for Front-end
resource "azurerm_public_ip" "frontendPublicIP" {
    name                         = "frontendPublicIP"
    location                     = var.location.value
    resource_group_name          = azurerm_resource_group.microservicesdemorg.name
    allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "frontendnic" {
    name                      = "frontendnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "frontend"

    ip_configuration {
        name                          = "myfrontendconfiguration"
        subnet_id                     = azurerm_subnet.websubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.1.10"
        public_ip_address_id          = azurerm_public_ip.frontendPublicIP.id
    }
}
resource "azurerm_network_interface_security_group_association" "frontendnic" {
    network_interface_id      = azurerm_network_interface.frontendnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "frontendinit" {
  template = file("./scripts/frontend.sh")
}
resource "azurerm_linux_virtual_machine" "frontend" {
    name                  = "frontend"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.frontendnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "frontenddisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "frontend"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.frontendinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create checkout Server
resource "azurerm_network_interface" "checkoutnic" {
    name                      = "checkoutnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "checkout"

    ip_configuration {
        name                          = "checkoutconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.10"
    }
}
resource "azurerm_network_interface_security_group_association" "checkoutnic" {
    network_interface_id      = azurerm_network_interface.checkoutnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "checkoutinit" {
  template = file("./scripts/checkout.sh")
}
resource "azurerm_linux_virtual_machine" "checkout" {
    name                  = "checkout"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.checkoutnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "checkoutdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "checkout"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.checkoutinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create ad Server
resource "azurerm_network_interface" "adnic" {
    name                      = "adnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "ad"

    ip_configuration {
        name                          = "adconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.11"
    }
}
resource "azurerm_network_interface_security_group_association" "adnic" {
    network_interface_id      = azurerm_network_interface.adnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "adinit" {
  template = file("./scripts/ad.sh")
}
resource "azurerm_linux_virtual_machine" "ad" {
    name                  = "ad"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.adnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "addisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "ad"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.adinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create recommendation Server
resource "azurerm_network_interface" "recommendationnic" {
    name                      = "recommendationnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "recommendation"

    ip_configuration {
        name                          = "recommendationconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.12"
    }
}
resource "azurerm_network_interface_security_group_association" "recommendationnic" {
    network_interface_id      = azurerm_network_interface.recommendationnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "recommendationinit" {
  template = file("./scripts/recommendation.sh")
}
resource "azurerm_linux_virtual_machine" "recommendation" {
    name                  = "recommendation"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.recommendationnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "recommendationdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "recommendation"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.recommendationinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create payment Server
resource "azurerm_network_interface" "paymentnic" {
    name                      = "paymentnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "payment"

    ip_configuration {
        name                          = "paymentconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.13"
    }
}
resource "azurerm_network_interface_security_group_association" "paymentnic" {
    network_interface_id      = azurerm_network_interface.paymentnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "paymentinit" {
  template = file("./scripts/payment.sh")
}
resource "azurerm_linux_virtual_machine" "payment" {
    name                  = "payment"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.paymentnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "paymentdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "payment"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.paymentinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create email Server
resource "azurerm_network_interface" "emailnic" {
    name                      = "emailnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "email"

    ip_configuration {
        name                          = "emailconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.14"
    }
}
resource "azurerm_network_interface_security_group_association" "emailnic" {
    network_interface_id      = azurerm_network_interface.emailnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "emailinit" {
  template = file("./scripts/emails.sh")
}
resource "azurerm_linux_virtual_machine" "email" {
    name                  = "email"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.emailnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "emaildisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "email"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.emailinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create productcatalog Server
resource "azurerm_network_interface" "productcatalognic" {
    name                      = "productcatalognic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "productcatalog"

    ip_configuration {
        name                          = "productcatalogconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.15"
    }
}
resource "azurerm_network_interface_security_group_association" "productcatalognic" {
    network_interface_id      = azurerm_network_interface.productcatalognic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "productcataloginit" {
  template = file("./scripts/productcatalog.sh")
}
resource "azurerm_linux_virtual_machine" "productcatalog" {
    name                  = "productcatalog"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.productcatalognic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "productcatalogdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "productcatalog"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.productcataloginit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create shipping Server
resource "azurerm_network_interface" "shippingnic" {
    name                      = "shippingnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "shipping"

    ip_configuration {
        name                          = "shippingconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.16"
    }
}
resource "azurerm_network_interface_security_group_association" "shippingnic" {
    network_interface_id      = azurerm_network_interface.shippingnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "shippinginit" {
  template = file("./scripts/shipping.sh")
}
resource "azurerm_linux_virtual_machine" "shipping" {
    name                  = "shipping"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.shippingnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "shippingdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "shipping"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.shippinginit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create currency Server
resource "azurerm_network_interface" "currencynic" {
    name                      = "currencynic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "currency"

    ip_configuration {
        name                          = "currencyconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.17"
    }
}
resource "azurerm_network_interface_security_group_association" "currencynic" {
    network_interface_id      = azurerm_network_interface.currencynic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "currencyinit" {
  template = file("./scripts/currency.sh")
}
resource "azurerm_linux_virtual_machine" "currency" {
    name                  = "currency"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.currencynic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "currencydisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "currency"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.currencyinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create cart Server
resource "azurerm_network_interface" "cartnic" {
    name                      = "cartnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "cart"

    ip_configuration {
        name                          = "cartconfiguration"
        subnet_id                     = azurerm_subnet.appsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.3.18"
    }
}
resource "azurerm_network_interface_security_group_association" "cartnic" {
    network_interface_id      = azurerm_network_interface.cartnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "cartinit" {
  template = file("./scripts/carts.sh")
}
resource "azurerm_linux_virtual_machine" "cart" {
    name                  = "cart"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.cartnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "cartdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "cart"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.cartinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}

#Create redis Server
resource "azurerm_network_interface" "redisnic" {
    name                      = "redisnic"
    location                  = var.location.value
    resource_group_name       = azurerm_resource_group.microservicesdemorg.name
    internal_dns_name_label       = "redis"

    ip_configuration {
        name                          = "redisconfiguration"
        subnet_id                     = azurerm_subnet.dbsubnet1.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.0.5.10"
    }
}
resource "azurerm_network_interface_security_group_association" "redisnic" {
    network_interface_id      = azurerm_network_interface.redisnic.id
    network_security_group_id = azurerm_network_security_group.cswdemonsg.id
}
data "template_file" "redisinit" {
  template = file("./scripts/redis.sh")
}
resource "azurerm_linux_virtual_machine" "redis" {
    name                  = "redis"
    location              = var.location.value
    resource_group_name   = azurerm_resource_group.microservicesdemorg.name
    network_interface_ids = [azurerm_network_interface.redisnic.id]
    size                  = "Standard_DS3_v2"

    os_disk {
        name              = "redisdisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts-gen2"
        version   = "latest"
    }

    computer_name  = "redis"
    admin_username = "azureuser"
    disable_password_authentication = true
    custom_data = base64encode(data.template_file.redisinit.rendered)

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.vm_ssh.public_key_openssh
    }
}
