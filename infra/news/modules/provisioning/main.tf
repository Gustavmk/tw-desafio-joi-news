

resource "null_resource" "main" {
  connection {
    host        = ""
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source      = var.source_script
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      "/home/ec2-user/provision.sh ${local.ecr_url}quotes:latest"
    ]
  }
}