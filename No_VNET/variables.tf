variable "location" {
  description = "The Azure location where the resources will be created."
  type        = string
  default     = "eastus2"
}

variable "resource_prefix" {
  description = "The prefix for the resource names."
  type        = string
  default     = "aibnovnet"
}

variable "subscription_id" {
  description = "The Azure subscription ID."
  type        = string
  default     = "3ab3f568-ab27-413c-be5a-7a1cc89a8104"
}
