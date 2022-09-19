output "access-frontend-at" {
    value = join(":",list(aws_instance.frontend.public_ip,"8080"))
    description = "The instance name for the fronend instance"
}
output "frontend" {
    value = aws_instance.frontend.private_ip
    description = "The instance name for the fronend instance"
}
output "checkout" {
    value = aws_instance.checkout.private_ip
    description = "The instance name for the checkout instance"
}
output "ad" {
    value = aws_instance.ad.private_ip
    description = "The instance name for the ad instance"
}
output "recommendation" {
    value = aws_instance.recommendation.private_ip
    description = "The instance name for the recommendation instance"
}
output "payment" {
    value = aws_instance.payment.private_ip
    description = "The instance name for the payment instance"
}
output "emails" {
    value = aws_instance.emails.private_ip
    description = "The instance name for the emails instance"
}
output "productcatalog" {
    value = aws_instance.productcatalog.private_ip
    description = "The instance name for the productcatalog instance"
}
output "shipping" {
    value = aws_instance.shipping.private_ip
    description = "The instance name for the shipping instance"
}
output "currency" {
    value = aws_instance.currency.private_ip
    description = "The instance name for the currency instance"
}
output "carts" {
    value = aws_instance.carts.private_ip
    description = "The instance name for the carts instance"
}
output "redis" {
    value = aws_instance.redis.private_ip
    description = "The instance name for the redis instance"
}
