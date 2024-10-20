variable "prefix" {
    description = "The prefix which should be used for all resources in this example."
    default = "huong"
}

variable "tags" {
    type = map
    default = {
        "Environment": "dev",
        "Owner": "HuongTTT13"
        }
}

variable "VMnum" {
    description = "Number of VM resources to be created behind the load balancer."
    default = 2
}

#Network variables
variable "admin_username" {
    default = "huong"
    description = "Admin User"
}

variable "admin_password" {
    default = "Lang1314"
    description = "Admin Password"
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  default = "southeastasia"
}
variable "number_vm" {
  description = "Number of VMs."
  default     = 1
}

variable "vm_size" {
  default     = "Standard_B1s"
  description = "VM SKU"
}

variable "subscription_id" {
    default     = "64a9a252-e2ca-4cc3-af56-31bf09b86699"
    description = "subscription_id"
}

variable "packer_resource_group" {
    default = "HuongTTT13-Image-rg"
  description = "Resource group of the Packer image"
}

variable "packer_image_name" {
    default = "HuongTTT13Image"
  description = "Image name of the Packer image"
}