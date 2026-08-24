resource "tls_private_key" "MyLinuxBox" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

data "tls_public_key" "MyLinuxBox" {
  private_key_pem = tls_private_key.MyLinuxBox.private_key_pem
}
