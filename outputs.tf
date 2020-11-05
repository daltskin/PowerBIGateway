output "public_ip_address" {
  value = azurerm_windows_virtual_machine.vm.public_ip_address
}

output "storageKey" {
  value = azurerm_storage_account.pbigateway_storage_account.primary_access_key
}