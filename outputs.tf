output "result" {
  value = {
    IP = google_compute_address.public_ip.address,
    OS = "${var.OS_name}-${var.OS_version}",
    VM_NAME = var.vm_name
  }
}
