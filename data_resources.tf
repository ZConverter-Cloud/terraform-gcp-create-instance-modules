data "google_compute_zones" "get_available_zone" {}

data "google_compute_network" "get_network" {
  name = var.network_name
}