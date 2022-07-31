terraform {
  required_version = "~>1.2.6"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~>0.77.0"
    }
  }
}


data "yandex_compute_image" "my_image" {
  family = var.instance_family_image
}

resource "yandex_compute_instance" "vm" {
  name                      = "terraform-${var.instance_family_image}"
  zone                      = var.instance_zone
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  #status                    = "stopped"

  resources {
    cores         = 2
    core_fraction = 50
    memory        = 2
  }
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
    }
  }

  network_interface {
    subnet_id = var.vpc_subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
