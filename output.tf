	output "azurevm-ss_public_ip" {
		value = "${azurerm_public_ip.demo02group.fqdn}"
	}

	output "azurevm-ss_public_ip001" {
		value = "${azurerm_public_ip.demo02group.ip_address}"
	}

	output "public_ip_id" {
		description = "id of the public ip address provisoned."
		value 		= "${azurerm_lb.demo02group.*.id}"
	}

	output "public_ip_loadbalancer_id" {
 		description = "id of the availability set where the vms are provisioned."
		value       = "${azurerm_lb.demo02group.id}"
	}

	output "azurevm-ss_public_ip002" {
		value = "${azurerm_lb_backend_address_pool.demo02group.id}"
	}

	output "azurevm-ss_public_ip003" {
		value = "${azurerm_lb_nat_pool.demo02group.*.id}"
	}