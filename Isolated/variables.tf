variable "location" {
  description = "The Azure location where the resources will be created."
  type        = string
  default     = "eastus2"
}

variable "resource_prefix" {
  description = "The prefix for the resource names."
  type        = string
  default     = "aibisolated"
}

variable "subscription_id" {
  description = "The Azure subscription ID."
  type        = string
  default     = "49a8be25-7877-4460-a634-7c9c60a5be08"
}
