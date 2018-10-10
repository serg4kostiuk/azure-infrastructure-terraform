resource "random_string" "fqdn" {
    length = 5
    special = false
    upper = false
    number = false
}

# ********************** VNET / SUBNET ********************** #
# Create virtual network
resource "azurerm_virtual_network" "demo02group" {
    name = "${var.dns_name}-virt-network"
    address_space = [
        "10.0.0.0/16"]
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    tags = "${var.tags}"
}

resource "azurerm_subnet" "demo02group" {
    name = "${var.dns_name}-subnet"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    virtual_network_name = "${azurerm_virtual_network.demo02group.name}"
    address_prefix = "10.0.2.0/24"
}

resource "azurerm_public_ip" "demo02group" {
    name = "${var.dns_name}-public-ip"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    public_ip_address_allocation = "static"
    domain_name_label = "${random_string.fqdn.result}"
    tags = "${var.tags}"
}

# ********************** CREATE LOAD BALANCER **********************
resource "azurerm_lb" "demo02group" {
    name = "${var.dns_name}-lb"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    tags = "${var.tags}"
    
    frontend_ip_configuration {
        name = "${var.dns_name}-publicIPAddress"
        public_ip_address_id = "${azurerm_public_ip.demo02group.id}"
    }
}

resource "azurerm_lb_backend_address_pool" "demo02group" {
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    loadbalancer_id = "${azurerm_lb.demo02group.id}"
    name = "${var.dns_name}-BEAddressPool"
}

resource "azurerm_lb_nat_pool" "demo02group" {
    count = 3
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    name = "${var.dns_name}-ssh"
    loadbalancer_id = "${azurerm_lb.demo02group.id}"
    protocol = "Tcp"
    frontend_port_start = 50000
    frontend_port_end = 50100
    backend_port = 22
    frontend_ip_configuration_name = "${var.dns_name}-publicIPAddress"
}

resource "azurerm_lb_probe" "demo02group" {
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    loadbalancer_id = "${azurerm_lb.demo02group.id}"
    name = "${var.dns_name}-ssh-running-probe"
    port = "${var.application_port}"
}

resource "azurerm_lb_rule" "lbnatrule" {
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    loadbalancer_id = "${azurerm_lb.demo02group.id}"
    name = "${var.dns_name}-http"
    protocol = "Tcp"
    frontend_port = "${var.application_port}"
    backend_port = "${var.application_port}"
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.demo02group.id}"
    frontend_ip_configuration_name = "${var.dns_name}-publicIPAddress"
    probe_id = "${azurerm_lb_probe.demo02group.id}"
}

# ********************** CREATE SCALE SET **********************
resource "azurerm_virtual_machine_scale_set" "demo02group" {
    name = "demo02group"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    upgrade_policy_mode = "Manual"
    #tags    = "${var.tags}"
    
    sku {
        #name     = "Standard_B2s"
        name = "Standard_B1ms"
        tier = "Standard"
        capacity = 1
    }
    
    storage_profile_image_reference {
        publisher = "OpenLogic"
        offer = "CentOS"
        sku = "7.0"
        version = "7.0.20150128"
    }
    
    storage_profile_os_disk {
        name = ""
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    
    storage_profile_data_disk {
        lun = 0
        caching = "ReadWrite"
        create_option = "Empty"
        disk_size_gb = 5
    }
    
    os_profile {
        computer_name_prefix = "demo02-vm-centos"
        admin_username = "${var.admin_user}"
        admin_password = "${var.admin_password}"
        #custom_data          = "${file("web.conf")}"
    }
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/serg/.ssh/authorized_keys"
            key_data = "${file("~/.ssh/id_rsa.pub")}"
        }
    }
    
    network_profile {
        name = "${var.dns_name}-terraform-netw-profile"
        primary = true
        
        ip_configuration {
            primary = true
            name = "${var.dns_name}-IPConfiguration"
            subnet_id = "${azurerm_subnet.demo02group.id}"
            load_balancer_backend_address_pool_ids = [
                "${azurerm_lb_backend_address_pool.demo02group.id}"]
            load_balancer_inbound_nat_rules_ids = [
                "${element(azurerm_lb_nat_pool.demo02group.*.id, count.index)}"]
        }
    }
    tags = "${var.tags}"
}

# ********************** AUTOSCALE SETTING **********************
resource "azurerm_autoscale_setting" "test" {
    name = "${var.dns_name}-scale-settings"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    location = "${var.location}"
    target_resource_id = "${azurerm_virtual_machine_scale_set.demo02group.id}"
    
    profile {
        name = "defaultProfile"
        
        capacity {
            default = 1
            minimum = 1
            maximum = 3
        }
        
        rule {
            metric_trigger {
                metric_name = "Percentage CPU"
                metric_resource_id = "${azurerm_virtual_machine_scale_set.demo02group.id}"
                time_grain = "PT1M"
                statistic = "Average"
                time_window = "PT5M"
                time_aggregation = "Average"
                operator = "GreaterThan"
                threshold = 50
            }
            
            scale_action {
                direction = "Increase"
                type = "ChangeCount"
                value = "1"
                cooldown = "PT1M"
            }
        }
        
        rule {
            metric_trigger {
                metric_name = "Percentage CPU"
                metric_resource_id = "${azurerm_virtual_machine_scale_set.demo02group.id}"
                time_grain = "PT1M"
                statistic = "Average"
                time_window = "PT5M"
                time_aggregation = "Average"
                operator = "LessThan"
                threshold = 25
            }
            
            scale_action {
                direction = "Decrease"
                type = "ChangeCount"
                value = "1"
                cooldown = "PT1M"
            }
        }
    }
}