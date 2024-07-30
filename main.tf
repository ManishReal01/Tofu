terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.14"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
}

provider "docker" {
}

provider "local" {
}

resource "docker_image" "vr_csr" {
  name         = "vrnetlab/vr-csr:16.09.05"
  keep_locally = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "local_file" "clab_topology" {
  content  = <<EOF
name: single_router_lab

topology:
  nodes:
    csr-r1:
      kind: vr-csr
      image: vrnetlab/vr-csr:16.09.05
      config:
        interfaces:
          - name: eth0
            type: ethernet
            ip: 192.168.1.1/24
          - name: eth1
            type: ethernet
            ip: 192.168.2.1/24

  links:
    - endpoints:
      - node: csr-r1
        interface: eth0
      - node: network1
        interface: eth0
    - endpoints:
      - node: csr-r1
        interface: eth1
      - node: network2
        interface: eth0

EOF
  filename = "${path.module}/router.clab.yml"
}

resource "null_resource" "deploy_clab" {
  provisioner "local-exec" {
    command = "containerlab deploy --topo ${local_file.clab_topology.filename} --reconfigure"
  }

  triggers = {
    clab_file = local_file.clab_topology.content
  }
}

