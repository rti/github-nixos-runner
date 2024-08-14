terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source = "registry.terraform.io/hetznercloud/hcloud"
    }
  }

  backend "local" {
    path = ".tofu/tofu.tfstate"
  }
}

variable "hcloud_token" {
  sensitive = true
}

variable "location" {
  default = "fsn1"
}

variable "machineCount" {
  # ALWAYS sync with machineCount in flake.nix
  default = 5
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "roti_yubikey_5_nano" {
  name       = "roti_yubikey_5_nano"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3jk/XCP/eTLZYWA6vA3higmyVcPQAgLH6Dh/1Zf7SioGApmoETxu3d7IkUt+NujzyJFihg891m3x1V7gOWTQg6KidmdU6V5E2weNgSBnI3V1Vn2TePIn5BmnK6heBiw1hLnzVcDvBIhxVPfsePmGHzt9iYlgrp3bCv1xwsSsZ8yxmPE/O/3TjvIR5XMo+QwUMg1/Xsxx5+aO7qGASwsWIj4NmfEbh9An9vzz++S7f+C//WEY1IFLzM1DmQCFhvVxM+IGZ7eeeT53+SNmfQIMADAgBIdhK1OAtGGffUKvigZBTlIhK3abIKOyUq+WFcncJMn0D/eMlpB7KbphxZPnO9bDU+ODmijCPSpjSZs8bigHweTFjcKiJAzTqUifaWVWjEx/zetnsbiq1jaVhgzZclgiwupZzTbYilEpsTdEOAEICbVnBZqG1QtHmI5YcCudlOhUwnJgFTNwVTMBKKknxTEBiFJMtr62kREOJDeAD/ohpAtOva660dH1zNvfxmUvpbpSwwjp8ngIkCT6JrhCdjBIy2bFqgCtpBTvOxnZnb5nXuMIgTETVPtffD1AuP6vEa/gLyWUhukiTATcX22i2NahOEDS0USRLXYKeB8HCEu3j7J8prf69Md+t+2hY3/BY5mtj28UKG75wTZh/UzDtso1D0GSbaSvZSab91uY4AQ== cardno:23_118_572"
}

resource "hcloud_ssh_key" "roti_yubikey_5_nfc" {
  name       = "roti_yubikey_5_nfc"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsnanR1klGRoD8GCh5vUhXy/R9XGPYSTnwnZK/wXp872tLVgkXLuTgDS1KUw1v58wzM08sATXyy9nprDjMGTkQj4fpiEq6/2hMdaMQ5Dw0FdxU/EFGQebXnNrUAU5yZyu7/kVfu638TuYLTg/fVp5wgT/aOLrpRqq8A2qOQMNcHU9zw0lH4QjcsKaCj9oUcAZtwVlLGeNdtwnaFKE3VtkO+J10Dy5V74xHCwQZLacSbZRNI0wbsIZHqzOVOXugQLU9/8Bl3MQPf3pywUWZeG9A460HZpk1isZSSNAkCkLCcna4qmok5psc6m6UpFWLOZSwnxNn0pYyscyt6NsIlXkxyhN3uR9/ffpE30zYy1zXC5g7tjOuh45FSWG3M0Yudt+Hn0boQVwdxCYg/3WGw2XpOxkGyCnN20ETGp1NzCB8FCctTGqJWWme5VrloU1O2zJ0BcMnkHhouqgpP73f5QttBX6eOQKJ4uV+1cXP9jrlj78cGOwLpnRBZGSRUf50V+BXgV4A+vaQ2bfb4ghfRmfoTLzG4lgPZRHhBbkGhoGDbHjwn5Oc4VGD4EXThkv3dHBCBK4pugeJJR5yWzA+Tv62PFQNE0eg/rrO74jZc4rWRjaweke2j5hkf05GaxlzDjf0KJFW0oR/rGJDkP9m0mu5rwFESoqvEQ1lxAHDjyOErw== cardno:20_560_926"
}

resource "hcloud_server" "github-runner" {
  count       = var.machineCount 
  name        = "github-runner-${count.index + 1}"
  server_type = "cx11"
  image       = "debian-12"
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.roti_yubikey_5_nano.id, hcloud_ssh_key.roti_yubikey_5_nfc.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  labels = {
    os-flavour = "nixos"
  }

  provisioner "local-exec" {
    command = <<EOF
      echo ${self.ipv4_address} > public-ipv4-${count.index + 1}
    EOF
  }
}

