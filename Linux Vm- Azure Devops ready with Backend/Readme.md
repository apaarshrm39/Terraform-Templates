## lINUX vm for azure:

1) These are the Variables that we are using:
variable "resource_group_name" { default = "ap-rg-demo-test" }
variable "resource_group_location" { default = "eastus" }
variable "storage_account_name" {default = "######"}
variable "container_name" {default = "######"}
variable "key" {default = "terraform.tfstate"}

2) Kindly Give the Variable value in command line or Azure Devops Terraform job like:
-var "resource_group_name = apaar_rg" -var "resource_group_location = westus"
