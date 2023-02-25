resource "google_compute_disk" "add_disk" {
  count = length(var.additional_volumes)

  name = "${var.vm_name}-disk-${count.index}"
  size = var.additional_volumes[count.index]
  type = "pd-ssd"
  zone = data.google_compute_zones.get_available_zone.names[0]
}

resource "google_compute_attached_disk" "attach_disk" {
  count = length(google_compute_disk.add_disk.*.id)

  instance = google_compute_instance.create_gcp_instance.self_link
  disk     = google_compute_disk.add_disk[count.index].self_link
}