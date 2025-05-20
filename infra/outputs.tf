output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
  depends_on  = [azurerm_linux_virtual_machine.main]
}

output "vm_ssh_connection" {
  description = "SSH connection string for the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
  depends_on  = [azurerm_linux_virtual_machine.main]
}

output "api_url" {
  description = "URL to access the API"
  value       = "http://${azurerm_public_ip.main.ip_address}:${var.api_port}"
  depends_on  = [azurerm_linux_virtual_machine.main]
}