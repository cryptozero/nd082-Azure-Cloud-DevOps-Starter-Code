variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "test"
}

# The project is run in a sandbox with restricted location, the project is uses de predefined RG using data
# (see variable udacity_resource_group).
# This behaviour could be improved using conditional logic to detect the environment, for simplicity this logic has
# not been implemented

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "germanywestcentral"
}

variable "username" {
  description = "Username for VM"
  default = "vmuser"
}

variable "password"{
  description = "Password for VM"
  default = "Locopass12!"
}

variable udacity_resource_group{
  description = "Udacity default resource group for devops deploys"
  default = {
    name = "Azuredevops",
    location = "East US"
  }
}

variable vmcount{
  description = "Number of virtual machines"
  default = 2
}

variable vm_image{
  description = "VM custom image reference name"
  default = "Ubuntu-1804-busybox"
}

variable project_tags{
  description = "Required project tags"
  default = {
    project = "webserver"
    created_by = "terraform"
    environment = "test"
  }
}
