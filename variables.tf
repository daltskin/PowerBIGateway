variable "location" {
  type = string
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
}

variable "storage_container_name" {
  type    = string
  default = "pbigateway"
}

variable "aad_app_id" {
  type        = string
  description = "AAD App Id"
}

variable "aad_app_secret" {
  type        = string
  description = "AAD App secret"
}

variable "tenant_id" {
  type        = string
  description = "AAD Tenant Id"
}

variable "gateway_name" {
  type        = string
  description = "Power BI Data Gateway Cluster name"
}

variable "gateway_region_key" {
  type        = string
  description = "Power BI Data Gateway region eg: uksouth"
}

variable "gateway_recovery_key" {
  type        = string
  description = "Power BI Data Gateway recovery key"
}

variable "gateway_admin_ids" {
  type        = string
  description = "Comma separated list of AAD Object IDs eg: '57859c9a-0483-4c1a-8d42-e8c2e8e9550a,12345c9a-0483-4c1a-8d42-e8c2e8e9554z'"
}
