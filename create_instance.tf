locals {
  metadata_startup_script = var.OS_name != "windows" && var.user_data_file_path != null && var.user_data_file_path != "null" ? templatefile(
    "${path.module}/startup_script_sh.tftpl",
    {
      userdata = var.OS_name != "windows" ? fileexists(var.user_data_file_path) != false ? file(var.user_data_file_path) : null : null
    }
  ) : null

  windows_startup_script_ps1 = var.OS_name == "windows" && var.user_data_file_path != null && var.user_data_file_path != "null" ? templatefile(
    "${path.module}/startup_script_ps1.tftpl",
    {
      userdata = var.OS_name == "windows" ? fileexists(var.user_data_file_path) != false ? file(var.user_data_file_path) : null : null
    }
  ) : null
}

resource "google_compute_instance" "create_gcp_instance" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = data.google_compute_zones.get_available_zone.names[0]

  boot_disk {
    initialize_params {
      image = "${local.OS_list[var.OS_name][var.OS_version].project}/${local.OS_list[var.OS_name][var.OS_version].family}"
      size = 50
    }
    auto_delete = true
  }

  tags = ["${var.vm_name}-tag"]
  metadata_startup_script = local.metadata_startup_script
  metadata = {
    windows-startup-script-ps1 = local.windows_startup_script_ps1
    ssh-keys = var.ssh_public_key != null ? "${var.user_name != null ? var.user_name : var.vm_name}:${var.ssh_public_key}" : null
    user-data = var.OS_name != "windows" ? fileexists(var.user_data_file_path) != false ? file(var.user_data_file_path) : null : null
  }

  network_interface {
    network = var.network_name
    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }
}
