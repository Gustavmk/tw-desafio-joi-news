

resource "null_resource" "quotes_provision" {
  connection {
    host        = "${aws_instance.quotes.public_ip}"
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file("${path.module}/../id_rsa")}"
  }
  provisioner "file" {
    source      = "${path.module}/provision-quotes.sh"
    destination = "/home/ec2-user/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/provision.sh",
      "/home/ec2-user/provision.sh ${local.ecr_url}quotes:latest"
    ]
  }
}