/*resource "azurerm_virtual_machine_extension" "demo02group" {
    name 					= "custom_apache"
    location 				= "${var.location}"
    resource_group_name   = "${azurerm_resource_group.demo02group.name}"
    virtual_machine_name 	= "${azurerm_virtual_machine_scale_set.demo02group.name}"
    publisher 			= "Microsoft.OSTCExtensions"
    type 					= "CustomScriptForLinux"
    type_handler_version 	= "1.2"
    
    settings = <<SETTINGS
  {
	"fileUris": [
	"https://"${azurerm_storage_account.storageaccount.name}.blob.core.windows.net/${azurerm_storage_container.demo02group.name}/apache_php.sh"
	],
	"commandToExecute": "sh apache_php.sh"
  }
SETTINGS
    
    tags {
        group = "LinuxAcademy"
    }
}*/
