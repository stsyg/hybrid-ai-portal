variable "project_name" {
  description = "Base project name prefix"
  type        = string
  default     = "js-haip"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "js-hybrid-ai-portal"
}
