variable "location" {
    type    = string
    default = "uksouth"
}

variable "admin_username" {
  type        = string
  description = "Administrator user name for virtual machine"
  default     = "pbi_user"
}

variable "admin_password" {
  type        = string
  description = "Password must meet Azure complexity requirements"
}

variable "prefix" {
  type    = string
  default = "my"
}

variable "sku" {
    type    = string
    default = "2019-Datacenter"
}

variable "size" {
    type    = string
    default = "Standard_D2_v2"
}

variable "vm_name" {
    type    = string
    default = "pbiVM"
}

variable "storage_account_name" {
    type    = string
    default = "pbigatewaystorage"
}

variable "storage_container_name" {
    type    = string
    default = "pbigateway"
}

variable "aad_app_id" {
    type    = string
}

variable "aad_app_secret" {
    type    = string
}

variable "tenant_id" {
    type    = string
}

variable "gateway_name" {
    type    = string
}

variable "gateway_region" {
    type    = string
}

variable "gateway_recovery_key" {
    type    = string
}

variable "gateway_admin_ids" {
    type    = string
}