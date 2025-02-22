terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
  }
}

provider "virtualbox" {}

variable "settings" {
  type = map(any)
  default = {
    cluster_name = "Kubernetes Cluster"
    control_ip   = "10.0.0.10"
    dns_servers  = ["8.8.8.8", "1.1.1.1"]
    pod_cidr     = "172.16.1.0/16"
    service_cidr = "172.17.1.0/18"

    control_cpu    = 2
    control_memory = 4096
    worker_count   = 2
    worker_cpu     = 1
    worker_memory  = 2048

    box       = "bento/ubuntu-24.04"
    calico    = "3.26.0"
    dashboard = "2.7.0"
    kubernetes = "1.31.0-*"
    os        = "xUbuntu_24.04"
  }
}

# Master Node
resource "virtualbox_vm" "controlplane" {
  name   = "node_master"
  image  = var.settings["box"]
  cpus   = var.settings["control_cpu"]
  memory = var.settings["control_memory"]

  network_adapter {
    type = "hostonly"
    host_interface = var.settings["control_ip"]
  }

  provisioner "file" {
    source      = "scripts/install_kubernetes.sh"
    destination = "/tmp/install_kubernetes.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_kubernetes.sh && /tmp/install_kubernetes.sh"
    ]
  }
}

# Worker Nodes
resource "virtualbox_vm" "worker" {
  count  = var.settings["worker_count"]
  name   = "node_0${count.index + 1}"
  image  = var.settings["box"]
  cpus   = var.settings["worker_cpu"]
  memory = var.settings["worker_memory"]

  network_adapter {
    type = "hostonly"
    host_interface = "10.0.0.${11 + count.index}"
  }

  provisioner "file" {
    source      = "scripts/common.sh"
    destination = "/tmp/common.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/common.sh && /tmp/common.sh",
      "bash /tmp/node.sh"
    ]
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
