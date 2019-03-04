# Add public key resource
resource "hcloud_ssh_key" "server_admin" {
  name       = "server_admin"
  public_key = "${file(var.ssh_public_key)}"
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}

# Bootstrap and initialize server
resource "hcloud_server" "server" {
  name        = "mangos-server"
  image       = "${var.server_image}"
  server_type = "${var.server_type}"
  ssh_keys    = ["${hcloud_ssh_key.server_admin.id}"]

  connection {
    private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "file" {
    source      = "${path.module}/hack/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = "/bin/bash /root/bootstrap.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/hack/build.sh"
    destination = "/root/build.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export MANGOS_SERVER_PUBLIC_IP=${hcloud_server.server.ipv4_address}",
      "/bin/bash /root/build.sh",
    ]
  }
}
