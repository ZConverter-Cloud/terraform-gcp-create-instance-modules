# terraform-gcp-create-instnace-modules

> Before You Begin
> 
> Prepare
> 
> Start Terraform

## Before You Begin
To successfully perform this tutorial, you must have the following:
   * You need to install [git](https://git-scm.com/downloads) in advance to use it. - **Reboot Required**
   * Prepare available GCP accounts
   * Please refer to [the API activation manual](https://cloud.google.com/endpoints/docs/openapi/enable-api?hl=en) and the [service account setting manual](https://developers.google.com/workspace/guides/create-credentials?hl=en) to activate the Compute Engine API and create a service account on the project to be used and save it locally as json.

## Prepare
Prepare your environment for authenticating and running your Terraform scripts. Also, gather the information your account needs to authenticate the scripts.

### Install Terraform
   Install the latest version of Terraform **v1.3.0+**:

   1. In your environment, check your Terraform version.
      ```script
      terraform -v
      ```

      If you don't have Terraform **v1.3.0+**, then install Terraform using the following steps.

   2. From a browser, go to [Download Latest Terraform Release](https://www.terraform.io/downloads.html).

   3. Find the link for your environment and then follow the instructions for your environment. Alternatively, you can perform the following steps. Here is an example for installing Terraform v1.3.3 on Linux 64-bit.

   4. In your environment, create a temp directory and change to that directory:
      ```script
      mkdir temp
      ```
      ```script
      cd temp
      ```

   5. Download the Terraform zip file. Example:
      ```script
      wget https://releases.hashicorp.com/terraform/1.3.3/terraform_1.3.3_linux_amd64.zip
      ```

   6. Unzip the file. Example:
      ```script
      unzip terraform_1.3.3_linux_amd64.zip
      ```

   7. Move the folder to /usr/local/bin or its equivalent in Mac. Example:
      ```script
      sudo mv terraform /usr/local/bin
      ```

   8. Go back to your home directory:
      ```script
      cd
      ```

   9. Check the Terraform version:
      ```script
      terraform -v
      ```

      Example: `Terraform v1.3.3 on linux_amd64`.

##  Start Terraform

* To use terraform, you must have a terraform file of command written and a terraform executable.
* You should create a folder to use terraform, create a terraform.tf file, and enter the contents below.
   ```
   // Terraform block
   //
   // Set to support terraform 1.3.0 or later
   // provider is fixed at google's 4.53.1
   terraform {
      required_providers {
         google = {
            source  = "hashicorp/google"
            version = "4.53.1"
         }
      }
   }

   // The terraform_data variable uses the data entered by the user.
   //
   // It is composed of the provider's authentication information input box
   //
   // and the VM information input box using the object type. 
   //
   // Since there is a lot of data, it is recommended to write the data to be entered
   //
   // as JSON in advance and apply it using -var-file.
   variable "terraform_data" {
      type = object({
         provider = object({
            credentials_path = string
            region           = string
         })
         vm_info = object({
            vm_name = string
            OS = object({
               OS_name    = string
               OS_version = string
            })
            machine_type = string
            network_interface = object({
               network_name = string
               create_security_group_rules = optional(list(object({
                  direction        = optional(string, null)
                  protocol         = optional(string, null)
                  port_range_min   = optional(string, null)
                  port_range_max   = optional(string, null)
                  remote_ip_prefix = optional(string, null)
               })), null)
            })
            ssh_authorized_keys = optional(object({
               user_name      = optional(string, null)
               ssh_public_key = optional(string, null)
            }), null)
            user_data_file_path = optional(string, null)
            additional_volumes  = optional(list(number), [])
         })
      })
      default = {
         provider = {
            credentials_path = null
            region           = null
         }
         vm_info = {
            OS = {
               OS_name    = null
               OS_version = null
            }
            additional_volumes = []
            machine_type       = null
            network_interface = {
               create_security_group_rules = [{
                  direction        = null
                  port_range_max   = null
                  port_range_min   = null
                  protocol         = null
                  remote_ip_prefix = null
               }]
               network_name = null
            }
            ssh_authorized_keys = {
               ssh_public_key = null
               user_name      = null
            }
            user_data_file_path = null
            vm_name             = null
         }
      }
   }

   locals {
      credentials = file(var.terraform_data.provider.credentials_path)
   }

   // Authentication information of google
   //
   // Applying input information received through a variable called terraform_data
   provider "google" {
      credentials = local.credentials
      project     = jsondecode(local.credentials).project_id
      region      = var.terraform_data.provider.region
   }

   // Utilize the module and use the association format code stored in the GitHub.
   //
   // Start creating an instance by designating the data entered
   //
   // as the terraform_data variable as the variable in the module.
   module "create_gcp_instance" {
      source = "git::https://github.com/ZConverter-Cloud/terraform-gcp-create-instance-modules.git"

      vm_name             = var.terraform_data.vm_info.vm_name
      machine_type        = var.terraform_data.vm_info.machine_type
      user_data_file_path = var.terraform_data.vm_info.user_data_file_path
      additional_volumes  = var.terraform_data.vm_info.additional_volumes

      OS_name    = var.terraform_data.vm_info.OS.OS_name
      OS_version = var.terraform_data.vm_info.OS.OS_version

      network_name                = var.terraform_data.vm_info.network_interface.network_name
      create_security_group_rules = var.terraform_data.vm_info.network_interface.create_security_group_rules

      user_name      = var.terraform_data.vm_info.ssh_authorized_keys.user_name
      ssh_public_key = var.terraform_data.vm_info.ssh_authorized_keys.ssh_public_key
   }

   // After the module creates an instance,
   //
   // it outputs the information of the instance.
   output "result" {
      value = jsonencode(module.create_gcp_instance.result)
   }
   ```
* After creating the gcp_terraform.json file to enter the user's value, you must enter the contents below. 
* ***<sapn style="color:red">The gcp_terraform.json below is an example of a required value only. See below the Attributes table for a complete example.</span>***
*  ***<sapn style="color:red">There is an attribute table for input values under the script, so you must refer to it.</span>***
   ```
   {
      "terraform_data": {
         "provider": {
            "credentials_path": "C:/Users/tykim/config/cred.json",
            "region": "asia-northeast3"
         },
         "vm_info": {
            "vm_name": "terraform-test",
            "OS": {
               "OS_name": "centos",
               "OS_version": "7"
            },
            "machine_type": "e2-medium",
            "network_interface": {
               "network_name": "default"
            },
            "ssh_authorized_keys": {
               "user_name": "test",
               "ssh_public_key": "ssh-rsa AAAAB********************************"
            },
            "user_data_file_path": "C:/Users/tykim/config/user_data.sh",
            "additional_volumes": [
               50
            ]
         }
      }
   }
   ```
### Attribute Table
|Attribute|Data Type|Required|Default Value|Description|
|---------|---------|--------|-------------|-----------|
|terraform_data.provider.credentials_path|string|yes|None|Please refer to [service account setting](#before-you-begin) step.|
|terraform_data.provider.region|string|yes|None|Refer to [region or zone](https://cloud.google.com/compute/docs/regions-zones?hl=en#identifying_a_region_or_zone) and enter a region, not a zone|
|terraform_data.vm_info.vm_name|string|yes|None|Name of the virtual machine to use|
|terraform_data.vm_info.OS.OS_name|string|yes|None|Select and enter "centos", "ubuntu", and "windows"|
|terraform_data.vm_info.OS.OS_version|string|yes|None|Please refer to the following and enter your version - centos: [7,8,9],ubuntu: [16.04, 18.04, 20.04, 22.04], Windows: [2012, 2016, 2019, 2022]|
|terraform_data.vm_info.machine_type|string|yes|None|Refer to [this](https://cloud.google.com/compute/docs/general-purpose-machines?hl=en#e2-shared-core) and enter a machine name|
|terraform_data.vm_info.network_interface.network_name|string|yes|None|Enter the VPC network name you want to use|
|terraform_data.vm_info.network_interface.create_security_group_rules|list(object)|no|None|Add a new security group|
|terraform_data.vm_info.network_interface.create_security_group_rules.*.direction|string|no|None|ingress or egress|
|terraform_data.vm_info.network_interface.create_security_group_rules.*.protocol|string|no|None|Type one of tcp, udp, icmp, esp, ah, sctp, ipip, all|
|terraform_data.vm_info.network_interface.create_security_group_rules.*.port_range_min|string|no|None|Minimum Port Range|
|terraform_data.vm_info.network_interface.create_security_group_rules.*.port_range_max|string|no|None|Maximum Port Range|
|terraform_data.vm_info.network_interface.create_security_group_rules.*.remote_ip_prefix|string|no|None|ip to allow access|
|terraform_data.vm_info.ssh_authorized_keys.user_name|string|no|None|Name of connection information to use|
|terraform_data.vm_info.ssh_authorized_keys.ssh_public_key|string|no|None|Access information to use ssh key|
|terraform_data.vm_info.user_data_file_path|string|no|None|Path of user_data to apply|
|terraform_data.vm_info.additional_volumes|list(object)|no|None|Additional disks, add them according to the size of the disk you entered.|

* gcp_terraform.json Full Example

   ```
   {
      "terraform_data": {
         "provider": {
            "credentials_path": null,
            "region": null
         },
         "vm_info": {
            "vm_name": null,
            "OS": {
               "OS_name": null,
               "OS_version": null
            },
            "machine_type": null,
            "network_interface": {
               "network_name": null,
               "create_security_group_rules": [
                  {
                     "direction": null,
                     "protocol": null,
                     "port_range_min": null,
                     "port_range_max": null,
                     "remote_ip_prefix": null
                  }
               ]
            },
            "ssh_authorized_keys": {
               "user_name": null,
               "ssh_public_key": null
            },
            "user_data_file_path": null,
            "additional_volumes": []
         }
      }
   }
   ```

* **Go to the file path of Terraform.exe and Initialize the working directory containing the terraform configuration file.**

   ```
   terraform init
   ```
   * **Note**
       -chdir : When you use a chdir the usual way to run Terraform is to first switch to the directory containing the `.tf` files for your root module (for example, using the `cd` command), so that Terraform will find those files automatically without any extra arguments. (ex : terraform -chdir=\<terraform data file path\> init) - [terraform -chdir](https://developer.hashicorp.com/terraform/cli/commands#switching-working-directory-with-chdir)

* **Creates an execution plan. By default, creating a plan consists of:**
  * Reading the current state of any already-existing remote objects to make sure that the Terraform state is up-to-date.
  * Comparing the current configuration to the prior state and noting any differences.
  * Proposing a set of change actions that should, if applied, make the remote objects match the configuration.
   ```
   terraform plan -var-file=<Absolute path of gcp_terraform.json>
   ```
  * **Note**
	* -var-file : When you use a var-file Sets values for potentially many [input variables](https://www.terraform.io/docs/language/values/variables.html) declared in the root module of the configuration, using definitions from a ["tfvars" file](https://www.terraform.io/docs/language/values/variables.html#variable-definitions-tfvars-files). Use this option multiple times to include values from more than one file.
     * The file name of vars.tfvars can be changed.

* **Executes the actions proposed in a Terraform plan.**
   ```
   terraform apply -var-file=<Absolute path of gcp_terraform.json> -auto-approve
   ```
* **Note**
	* -auto-approve : Skips interactive approval of plan before applying. This option is ignored when you pass a previously-saved plan file, because Terraform considers you passing the plan file as the approval and so will never prompt in that case.
