
	resource "random_string" "fqdn" {
		length  = 5
		special = false
		upper   = false
		number  = false
	}

	# ********************** VNET / SUBNET ********************** #
	# Create virtual network
	resource "azurerm_virtual_network" "demo02group" {
		name                = "${var.dns_name}-virt-network"
		address_space       = ["10.0.0.0/16"]
		location            = "${var.location}"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		tags                = "${var.tags}"
	}

	resource "azurerm_subnet" "demo02group" {
		name                 = "${var.dns_name}-subnet"
		resource_group_name  = "${azurerm_resource_group.demo02group.name}"
		virtual_network_name = "${azurerm_virtual_network.demo02group.name}"
		address_prefix       = "10.0.2.0/24"
	}

	resource "azurerm_public_ip" "demo02group" {
		name                         = "${var.dns_name}-public-ip"
		location                     = "${var.location}"
		resource_group_name          = "${azurerm_resource_group.demo02group.name}"
		public_ip_address_allocation = "static"
		domain_name_label            = "${random_string.fqdn.result}"
		tags                         = "${var.tags}"
	}

	# **********************  NETWORK INTERFACES **********************
	resource "azurerm_network_security_group" "demo02group" {
		name                = "${var.dns_name}-NetworkSecurityGroup"
		location            = "${var.location}"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		tags                = "${var.tags}"

		security_rule {
			name                       = "${var.dns_name}SSH"
			priority                   = 100
			direction                  = "Inbound"
			access                     = "Allow"
			protocol                   = "Tcp"
			source_port_range          = "*"
			destination_port_range     = "22"
			source_address_prefix      = "*"
			destination_address_prefix = "*"
		}
		security_rule {
			name                       = "${var.dns_name}HTTP"
			priority                   = 1001
			direction                  = "Inbound"
			access                     = "Allow"
			protocol                   = "Tcp"
			source_port_range          = "*"
			destination_port_range     = "80"
			source_address_prefix      = "*"
			destination_address_prefix = "*"
		}
		security_rule {
			name                       = "${var.dns_name}MySQL"
			description                = "MySQL"
			priority                   = 110
			direction                  = "Inbound"
			access                     = "Allow"
			protocol                   = "Tcp"
			source_port_range          = "*"
			destination_port_range     = "3306"
			source_address_prefix      = "*"
			destination_address_prefix = "*"
		}
	}

	#---------------------------Create Load Balancer-----------------------------
	resource "azurerm_lb" "demo02group" {
		name                = "${var.dns_name}-lb"
		location            = "${var.location}"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		tags 				= "${var.tags}"

		frontend_ip_configuration {
			name                 = "${var.dns_name}-publicIPAddress"
			public_ip_address_id = "${azurerm_public_ip.demo02group.id}"
		}
	}

	resource "azurerm_lb_backend_address_pool" "demo02group" {
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		loadbalancer_id     = "${azurerm_lb.demo02group.id}"
		name                = "${var.dns_name}-BEAddressPool"
	}

	resource "azurerm_lb_nat_pool" "demo02group" {
		count                          = 1
		resource_group_name            = "${azurerm_resource_group.demo02group.name}"
		name                           = "${var.dns_name}-ssh"
		loadbalancer_id                = "${azurerm_lb.demo02group.id}"
		protocol                       = "Tcp"
		frontend_port_start            = 50000
		frontend_port_end              = 50100
		backend_port                   = 22
		frontend_ip_configuration_name = "${var.dns_name}-publicIPAddress"
	}

	resource "azurerm_lb_probe" "demo02group" {
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		loadbalancer_id     = "${azurerm_lb.demo02group.id}"
		name                = "${var.dns_name}-ssh-running-probe"
		port                = "${var.application_port}"
	}

	resource "azurerm_lb_rule" "lbnatrule" {
		resource_group_name            = "${azurerm_resource_group.demo02group.name}"
		loadbalancer_id                = "${azurerm_lb.demo02group.id}"
		name                           = "${var.dns_name}-http"
		protocol                       = "Tcp"
		frontend_port                  = "${var.application_port}"
		backend_port                   = "${var.application_port}"
		backend_address_pool_id        = "${azurerm_lb_backend_address_pool.demo02group.id}"
		frontend_ip_configuration_name = "${var.dns_name}-publicIPAddress"
		probe_id                       = "${azurerm_lb_probe.demo02group.id}"
		enable_floating_ip			   = true
	}

	#-------------------Create Scale set--------------------------------
	resource "azurerm_virtual_machine_scale_set" "demo02group" {
		name                = "demo02group"
		location            = "${var.location}"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		upgrade_policy_mode = "Manual"
		tags   			    = "${var.tags}"

		sku {
			name     = "Standard_B1ms"
			tier     = "Standard"
			capacity = 2
		}

		storage_profile_image_reference {
			publisher = "OpenLogic"
			offer     = "CentOS"
			sku       = "7.0"
			version   = "7.0.20150128"
		}

		storage_profile_os_disk {
			name              = ""
			caching           = "ReadWrite"
			create_option     = "FromImage"
			managed_disk_type = "Standard_LRS"
		}

		storage_profile_data_disk {
			lun            = 0
			caching        = "ReadWrite"
			create_option  = "Empty"
			disk_size_gb   = 5
		}

		os_profile {
			computer_name_prefix = "demo02-vm-centos"
			admin_username       = "${var.admin_user}"
			admin_password       = "${var.admin_password}"
			#custom_data          = "${file("web.conf")}"
		}

		network_profile {
			name    = "${var.dns_name}-terraform-netw-profile"
			primary = true

			ip_configuration {
				primary 							   = true
				name                                   = "${var.dns_name}-IPConfiguration"
				subnet_id                              = "${azurerm_subnet.demo02group.id}"
				load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.demo02group.id}"]
				load_balancer_inbound_nat_rules_ids    = ["${element(azurerm_lb_nat_pool.demo02group.*.id, count.index)}"]
			}
		}

		os_profile_linux_config {
			disable_password_authentication = true
			ssh_keys {
				path     = "/home/serg/.ssh/authorized_keys"
				key_data = "${file("~/.ssh/id_rsa.pub")}"
			}
		}
		/*
		connection {
	        #host 		= "${azurerm_public_ip.demo02group.fqdn}"
	        #host 		= "${element(azurerm_lb_nat_pool.demo02group.*.id, count.index)}"
	        #host 		= "40.121.69.188"
	        #host 		= "${azurerm_public_ip.demo02group.ip_address}"
	        host 		= "${azurerm_public_ip.demo02group.ip_address}"

	        user 		= "${var.admin_user}"
	        type 		= "ssh"
	        private_key = "${file("~/.ssh/id_rsa")}"
	        timeout 	= "1m"
	        agent 		= true
    	}
    	
    	provisioner "remote-exec" {
	        inline = [
	          "sudo yum update -y && yum install -y docker nano wget git",
	          "sudo systemctl enable docker && systemctl start docker",
	          "sudo docker pull skostiuk/apache-php:5.0",
	          "sudo docker run -d -p 8080:80 skostiuk/apache-php:5.0"
	        ]
	    } */
	}

	#-------------------Create Storage BLOB--------------------------------
	# Create storage account for boot diagnostics
	resource "azurerm_storage_account" "storageaccount" {
		name    			        = "diag${random_string.fqdn.result}"
		resource_group_name         = "${azurerm_resource_group.demo02group.name}"
		location                    = "${var.location}"
		account_tier                = "Standard"
		account_replication_type    = "LRS"
		tags                        = "${var.tags}"
	}

	resource "azurerm_storage_container" "demo02group" {
		name 				  = "demo02groupstor"
		resource_group_name   = "${azurerm_resource_group.demo02group.name}"
		storage_account_name  = "${azurerm_storage_account.storageaccount.name}"
		container_access_type = "private"
	}

	resource "azurerm_storage_blob" "demo02group" {
		name = "sample.vhd"
		resource_group_name    = "${azurerm_resource_group.demo02group.name}"
		storage_account_name   = "${azurerm_storage_account.storageaccount.name}"
		storage_container_name = "${azurerm_storage_container.demo02group.name}"
		type = "page"
		size = "5120"
	}

	# -------------- Create Mysql database ----------------------------
	resource "azurerm_mysql_server" "demo02group" {
		name                = "${var.dns_name}-wordpressdatabase"
		location            = "${var.location}"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		administrator_login = "serg"
		administrator_login_password = "4400MYsql!"
		version = "5.7"
		ssl_enforcement = "Disabled"

		sku {
			name = "B_Gen5_1"
			capacity = 1
			tier = "Basic"
			family = "Gen5"
		}

		storage_profile {
			storage_mb = 5120
			backup_retention_days = 10
			geo_redundant_backup = "Disabled"
		}
	}

	resource "azurerm_mysql_database" "demo02group" {
		name                = "testdatabase"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		server_name         = "${azurerm_mysql_server.demo02group.name}"
		charset             = "utf8"
		collation           = "utf8_unicode_ci"
	}

	resource "azurerm_mysql_firewall_rule" "demo02group" {
		name                = "${var.dns_name}-firewall-mysql-rule"
		resource_group_name = "${azurerm_resource_group.demo02group.name}"
		server_name         = "${azurerm_mysql_server.demo02group.name}"
		start_ip_address    = "0.0.0.0"
		end_ip_address      = "255.255.255.254"
	}

	#-------------------RUN SCRIPT--------------------------------

	resource "azurerm_virtual_machine_extension" "helloterraformvm" {
		name                 = "${var.dns_name}-hostname"
		location             = "${var.location}"
		#resource_group_name  = "${azurerm_resource_group.demo02group.name}"
		resource_group_name  = "test-res-group-terraform"
		virtual_machine_name = "myVM-test-nginx"
		#virtual_machine_name = "${azurerm_virtual_machine_scale_set.demo02group.name}"
		#publisher            = "Microsoft.OSTCExtensions"
		#type                 = "CustomScriptForLinux"
		publisher            = "Microsoft.Azure.Extensions"
		type                 = "CustomScript"
		type_handler_version = "2.0"
		#tags				 = "${var.tags}"

		settings = <<SETTINGS
			{
				"commandToExecute": "yum update -y && yum install -y docker nano wget git"
			}
		SETTINGS
	}



