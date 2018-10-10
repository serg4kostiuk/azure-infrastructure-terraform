variable "location" {
    description = "eastus, westus, northeurope, westeurope, southeastasia"
    default = "eastus"
}

variable "tags" {
    description = "Terraform Demo02"
    type = "map"
    
    default = {
        environment = "Terraform Demo02-test"
    }
}

variable "dns_name" {
    description = "Connect to your cluster using dnsName.location.cloudapp.azure.com"
    default = "demo02group"
}

variable "admin_user" {
    description = "User name to use as the admin account on the VMs that will be part of the VM Scale Set"
    default = "serg"
}

variable "admin_password" {
    description = "password of amin user on vm's"
    default = "4400lviv"
}

variable "application_port" {
    description = "The port that you want to expose to the external load balancer"
    default = 80
}

/* variable "resource_group_name" {
description = "The name of the resource group in which the resources will be created"
default     = "demo02group"
} */


