variable "ssh_public_key" {
  description = "SSH public key to be copied on machines"
  default = "~/.ssh/hetzner.pub"
}

variable "ssh_private_key" {
  description = "SSH private key to be used to log into machines"
  default = "~/.ssh/hetzner"
}

variable "server_image" {
  description = "Image to be used by server"
  default = "ubuntu-18.04"
}

variable "server_type" {
  description = "Hetzner server offer type name"
  default = "cx21"
}

variable "hcloud_token" {}
