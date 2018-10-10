# ********************** CREATE MYSQL DATABASE **********************
resource "azurerm_mysql_server" "demo02group" {
    name = "${var.dns_name}-wordpressdatabase"
    location = "${var.location}"
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
    name = "testdatabase"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    server_name = "${azurerm_mysql_server.demo02group.name}"
    charset = "utf8"
    collation = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "demo02group" {
    name = "${var.dns_name}-firewall-mysql-rule"
    resource_group_name = "${azurerm_resource_group.demo02group.name}"
    server_name = "${azurerm_mysql_server.demo02group.name}"
    start_ip_address = "0.0.0.0"
    end_ip_address = "255.255.255.254"
}