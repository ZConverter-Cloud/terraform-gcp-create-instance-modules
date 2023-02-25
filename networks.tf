resource "google_compute_address" "public_ip" {
  name = "${var.vm_name}-public-ip"
}

locals {
  ingress_list = var.create_security_group_rules != null ? [
    for data in var.create_security_group_rules:
    data
    if data.direction == "ingress"
  ] : []
  egress_list = var.create_security_group_rules != null ? [
    for data in var.create_security_group_rules:
    data
    if data.direction == "egress"
  ] : []
}

resource "google_compute_firewall" "ingress_firewall" {
  count = length(local.ingress_list)

  name = "${var.vm_name}-ingress-firewall-${count.index}"
  network = var.network_name
  source_tags = ["${var.vm_name}-tag"]

  direction = "INGRESS"
  priority = 1000 + count.index
  

  allow {
    protocol = local.ingress_list[count.index].protocol
    ports = local.ingress_list[count.index].port_range_min == "all" && local.ingress_list[count.index].port_range_max == "all" ? ["all"] : ["${local.ingress_list[count.index].port_range_min}-${local.ingress_list[count.index].port_range_max}"]
  }
  source_ranges = [local.ingress_list[count.index].remote_ip_prefix]
}

resource "google_compute_firewall" "egress_firewall" {
  count = length(local.egress_list)

  name = "${var.vm_name}-egress-firewall-${count.index}"
  network = var.network_name
  target_tags = ["${var.vm_name}-tag"]

  direction = "EGRESS"
  priority = 1000 + count.index

  allow {
    protocol = local.egress_list[count.index].protocol
    ports = local.egress_list[count.index].port_range_min == "all" && local.egress_list[count.index].port_range_max == "all" ? ["all"] : ["${local.egress_list[count.index].port_range_min}-${local.egress_list[count.index].port_range_max}"]
  }
  destination_ranges = [local.egress_list[count.index].remote_ip_prefix]
}