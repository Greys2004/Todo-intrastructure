provider "digitalocean"{
    token = var.DO_TOKEN
}

terraform{
    required_providers {
        digitalocean = {
            source  = "digitalocean/digitalocean"
            version = "~> 2.0"
        }
    }

    backend "s3"{
        endpoints = {
            s3 = "https://sfo3.digitaloceanspaces.com"
        }
        bucket = "devgav"
        key = "terraform.tfstate"
        skip_credentials_validation = true
        skip_requesting_account_id = true
        skip_metadata_api_check = true
        skip_s3_checksum = true
        region = "us-east-1"
    }
}

resource "digitalocean_project" "greys_server_project" {
    name        = "Greys Server Project"
    description = "Un servidor para cositas personales"
    resources = [digitalocean_droplet.greys_server_droplet.urn]
}

resource "digitalocean_ssh_key" "greys_server_ssh_key" {
    name = "greys-server-ssh-key2"
    public_key = file("./keys/greys_server.pub")
}

resource "digitalocean_droplet" "greys_server_droplet" {
    name   = "greysserver"
    size = "s-2vcpu-4gb-120gb-intel"
    image = "ubuntu-24-04-x64"
    region = "sfo3"
    ssh_keys = [digitalocean_ssh_key.greys_server_ssh_key.id]
    user_data = file("./docker-install.sh")

    provisioner "remote-exec" {
        inline = [ 
            "mkdir -p /projects",
            "mkdir -p /volumes/nginx/html",
            "mkdir -p /volumes/nhinx/certs",
            "mkdir -p /volumes/nginx/vhostd",
            "touch /projects/.env",
            "echo \"MYSQL_DB=${var.MYSQL_DB}\" >> /projects/.env",
            "echo \"MYSQL_HOST=${var.MYSQL_HOST}\" >> /projects/.env",
            "echo \"MYSQL_PASSWORD=${var.MYSQL_PASSWORD}\" >> /projects/.env",
            "echo \"MYSQL_USER=${var.MYSQL_USER}\" >> /projects/.env",
            "echo \"DOMAIN=${var.DOMAIN}\" >> /projects/.env",
            "echo \"USER_EMAIL=${var.USER_EMAIL}\" >> /projects/.env",
        ]
        connection {
            type = "ssh"
            user ="root"
            private_key = file("./keys/greys_server")
            host = self.ipv4_address
        }
    }

    provisioner "file" {
        source = "./containers/docker-compose.yml"
        destination =  "/projects/docker-compose.yml"
        connection {
            type = "ssh"
            user ="root"
            private_key = file("./keys/greys_server")
            host = self.ipv4_address
        }
    }
}


# esperar a que se intale
resource "time_sleep" "wait_docker_install" {
    depends_on = [ digitalocean_droplet.greys_server_droplet ]
    create_duration = "130s"
}

resource "null_resource" "init_api" {
    depends_on = [time_sleep.wait_docker_install]
    provisioner "remote-exec" {
        inline = [
        "cd /projects",
        "docker-compose up -d"
        ]
        connection {
            type = "ssh"
            user = "root"
            private_key = file("./keys/greys_server")
            host = digitalocean_droplet.greys_server_droplet.ipv4_address
        }
    }
}

# resource "null_resource" "init_nginx" {
#     depends_on = [time_sleep.wait_docker_install]
#     connection {
#         type = "ssh"
#         host = digitalocean_droplet.greys_server_droplet.ipv4_address
#         user = "root"
#         private_key = file("./keys/greys_server")
#     }
#     provisioner "remote-exec" {
#         inline = [
#             "docker container run --name=Adidas -dp 80:80 nginx"
#         ]
#     }
# }

# Hacer cd /
# docker cp adidads/. Adidas:/usr/share/nginx/html

# resource "null_resource" "copy_to_nginx_container" {
#     depends_on = [ null_resource.adidas_copy_folder, null_resource.init_nginx ]
#     connection {
#         type = "ssh"
#         user = "root"
#         private_key = file("./keys/greys_server")
#         host = digitalocean_droplet.greys_server_droplet.ipv4_address
#     }
#     provisioner "remote-exec" {
#         inline = [
#             "cd /",
#             "docker cp adidas/. Adidas:/usr/share/nginx/html"
#         ]
#     }
# }

# resource "null_resource" "adidas_copy_folder" {
#     provisioner "file" {
#         source = "./adidas"
#         destination = "/adidas"
#     }
#     connection {
#         type = "ssh"
#         host = digitalocean_droplet.greys_server_droplet.ipv4_address
#         user = "root"
#         private_key = file("./keys/greys_server")
#     }
# }

output "ip" {
    value = digitalocean_droplet.greys_server_droplet.ipv4_address
}