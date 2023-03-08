output "access-frontend-at" {
    value = join(":",tolist([azurerm_linux_virtual_machine.frontend.public_ip_address,"8080"]))
    description = "The instance name for the fronend instance"
}
output "frontend" {
    value = azurerm_linux_virtual_machine.frontend.private_ip_address
    description = "The instance IP for the frontend"
}
output "checkout" {
    value = azurerm_linux_virtual_machine.checkout.private_ip_address
    description = "The instance IP for the checkout"
}
output "ad" {
    value = azurerm_linux_virtual_machine.ad.private_ip_address
    description = "The instance IP for the ad"
}
output "recommendation" {
    value = azurerm_linux_virtual_machine.recommendation.private_ip_address
    description = "The instance IP for the recommendation"
}
output "payment" {
    value = azurerm_linux_virtual_machine.payment.private_ip_address
    description = "The instance name for the payment instance"
}
output "emails" {
    value = azurerm_linux_virtual_machine.email.private_ip_address
    description = "The instance name for the emails instance"
}
output "productcatalog" {
    value = azurerm_linux_virtual_machine.productcatalog.private_ip_address
    description = "The instance name for the productcatalog instance"
}
output "shipping" {
    value = azurerm_linux_virtual_machine.shipping.private_ip_address
    description = "The instance name for the shipping instance"
}
output "currency" {
    value = azurerm_linux_virtual_machine.currency.private_ip_address
    description = "The instance name for the currency instance"
}
output "cart" {
    value = azurerm_linux_virtual_machine.cart.private_ip_address
    description = "The instance name for the carts instance"
}
output "redis" {
    value = azurerm_linux_virtual_machine.redis.private_ip_address
    description = "The instance name for the redis instance"
}

output "vm_ssh" {
    value = tls_private_key.vm_ssh.private_key_pem
    sensitive = true
}
