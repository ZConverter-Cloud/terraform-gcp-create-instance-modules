terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.53.1"
    }
  }
}

variable "vm_name" {
  type = string
}

variable "OS_name" {
  type = string
}

variable "OS_version" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "network_name" {
  type    = string
  default = "default"
}

variable "create_security_group_rules" {
  type = list(object({
    direction        = optional(string,null)
    protocol         = optional(string,null)
    port_range_min   = optional(string,null)
    port_range_max   = optional(string,null)
    remote_ip_prefix = optional(string,null)
  }))
  default = [{
    direction        = null
    protocol         = null
    port_range_min   = null
    port_range_max   = null
    remote_ip_prefix = null
  }]
}

variable "user_name" {
  type = string
  default = null
}

variable "ssh_public_key" {
  type = string
  default = null
}

variable "user_data_file_path" {
  type = string
  default = null
}

variable "additional_volumes" {
  type = list(number)
  default = []
}

locals {
  windows_startup_script_ps1 = var.OS_name != "windows" || var.user_data_file_path == null && var.user_data_file_path == "null" ? null : <<-SCRIPT
$cmd_script = @"
${file(var.user_data_file_path)}
"@

$logFile = "C:\userdata.log"

if(Test-Path "C:\success_userdata"){
  Write-Output "------------------------" | Out-File -FilePath $logFile -Append
  Write-Output "$(Get-Date) - Start log" | Out-File -FilePath $logFile -Append
  Write-Output "$(Get-Date) - C:\success_userdata file exists. Script will be terminated." | Out-File -FilePath $logFile -Append
  Write-Output "$(Get-Date) - End log" | Out-File -FilePath $logFile -Append
  Write-Output "------------------------" | Out-File -FilePath $logFile -Append
  Exit
}

Write-Output "------------------------" | Out-File -FilePath $logFile -Append
Write-Output "$(Get-Date) - Start log" | Out-File -FilePath $logFile -Append

$cmd_script = $cmd_script -replace "<script>|<\/script>|<powershell>|<\/powershell>|rem cmd", ""
Write-Output "$(Get-Date) - replace script rules" | Out-File -FilePath $logFile -Append
$cmd_script | Out-File -FilePath "C:\userdata.cmd" -Encoding utf8 -Force
Write-Output "$(Get-Date) - userdata.cmd Created." | Out-File -FilePath $logFile -Append
for ($i = 1; $i -le 3; $i++) {
  try {
    Start-Process "C:\userdata.cmd" -Verb RunAs -Wait
    Add-Content $logFile "$(Get-Date) - C:\userdata.cmd was successfully executed on attempt #$i."
    New-Item -ItemType File -Path "C:\success_userdata" -Force
    break
  }
  catch {
    Add-Content $logFile "$(Get-Date) - An error occurred while running C:\userdata.cmd on attempt #$i. Error: $_"
  }
}

Write-Output "$(Get-Date) - End log" | Out-File -FilePath $logFile -Append
Write-Output "------------------------" | Out-File -FilePath $logFile -Append
  SCRIPT
  OS_list = {
    centos = {
      "7" = {
        family  = "centos-7"
        project = "centos-cloud"
      }
      "8" = {
        family  = "centos-stream-8"
        project = "centos-cloud"
      }
      "9" = {
        family  = "centos-stream-9"
        project = "centos-cloud"
      }
    }
    ubuntu = {
      "16.04" = {
        family  = "ubuntu-pro-1604-lts"
        project = "ubuntu-os-pro-cloud"
      }
      "18.04" = {
        family  = "ubuntu-1804-lts"
        project = "ubuntu-os-cloud"
      }
      "20.04" = {
        family  = "ubuntu-2004-lts"
        project = "ubuntu-os-cloud"
      }
      "22.04" = {
        family  = "ubuntu-2204-lts"
        project = "ubuntu-os-cloud"
      }
    }
    windows = {
      "2012" = {
        family  = "windows-2012-r2"
        project = "windows-cloud"
      }
      "2016" = {
        family  = "windows-2016"
        project = "windows-cloud"
      }
      "2019" = {
        family  = "windows-2019"
        project = "windows-cloud"
      }
      "2022" = {
        family  = "windows-2022"
        project = "windows-cloud"
      }
    }
  }
}
