terraform {
  required_version = "~>1.2.6"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~>0.77.0"
    }
  }

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "<bucket>"
    region     = "ru-central1-a"
    key        = "<key>"
    access_key = "<access_key>"
    secret_key = "<secret_key>"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

# Документация к провайдеру тут https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs#configuration-reference
# Настраиваем the Yandex.Cloud provider
provider "yandex" {
  service_account_key_file = file("~/sa.json")
  cloud_id                 = "<cloud_id>"
  folder_id                = "<folder_id>"
}


resource "yandex_vpc_network" "network-1" {
  name = "a"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "a-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "a-ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.129.0.0/24"]
}

module "ya_instance_1" {
  source                = "./modules/instance"
  instance_family_image = "lemp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet-1.id
  instance_zone         = yandex_vpc_subnet.subnet-1.zone
}

module "ya_instance_2" {
  source                = "./modules/instance"
  instance_family_image = "lamp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet-1.id
  instance_zone         = yandex_vpc_subnet.subnet-1.zone
}

resource "yandex_lb_network_load_balancer" "nlb" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 80
    protocol    = "tcp"
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.lb_tg.id}"

    healthcheck {
      healthy_threshold   = 4
      interval            = 4
      name = "http"
      timeout             = 3
      unhealthy_threshold = 4
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

resource "yandex_lb_target_group" "lb_tg" {
  name      = "my-target-group"
  region_id = "ru-central1"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address   = "${module.ya_instance_1.internal_ip_address_vm}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address   = "${module.ya_instance_2.internal_ip_address_vm}"
  }
}