variable "sub" {
  type = string
  description = "Subscription that will host the infrastructure"
}

variable "client_secret" {
  type        = string
  description = "Service principal client secret"
}

variable "client_id" {
  type        = string
  description = "Service principal client ID"
}

variable "tenant_id" {
  type        = string
  description = "Service principal tenant_id"
}

variable "location" {
  type = string
  description = "Location for the resources"
  default = "northeurope"
}

variable "env" {
  type = string
  description = "Environment of the resources"
  default = "dev"
}

variable "app" {
  type = string
  description = "Name of the app"
  default = "app"
}