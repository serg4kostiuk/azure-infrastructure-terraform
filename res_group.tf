
	# Configure the Microsoft Azure Provider
	provider "azurerm" {
		subscription_id = "${var.subscription_id}"
		client_id       = "${var.client_id}"
		client_secret   = "${var.client_secret}"
		tenant_id       = "${var.tenant_id}"
	}

	resource "azurerm_resource_group" "demo02group" {
		name     = "${var.dns_name}"
		location = "${var.location}"
		tags     = "${var.tags}"
	}