# ********************** NETWORK SECURITY GROUP **********************
resource "azurerm_network_security_group" "demo02group" {
    name = "${var.dns_name}-NetworkSecurityGroup"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    tags = "${var.tags}"
    
    security_rule {
        name = "${var.dns_name}SSH"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name = "${var.dns_name}HTTP"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name = "${var.dns_name}MySQL"
        description = "MySQL"
        priority = 110
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "3306"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}