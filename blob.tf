# ********************** CREATE STORAGE BLOB **********************
# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccount" {
    name = "diag${random_string.fqdn.result}"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    location = "${var.location}"
    account_tier = "Standard"
    account_replication_type = "LRS"
    tags = "${var.tags}"
}

resource "azurerm_storage_container" "demo02group" {
    name = "demo02groupstor"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    storage_account_name = "${azurerm_storage_account.storageaccount.name}"
    container_access_type = "private"
}

resource "azurerm_storage_blob" "demo02group" {
    name = "sample.vhd"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    storage_account_name = "${azurerm_storage_account.storageaccount.name}"
    storage_container_name = "${azurerm_storage_container.demo02group.name}"
    type = "page"
    size = "5120"
}