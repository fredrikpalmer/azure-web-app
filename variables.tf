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

variable "org" {
  type = string
  description = "Name of the app"
  default = "fp"
}

variable "team" {
  type = string
  description = "Name of the team"
  default = "team"
}

variable "domain" {
  type = string
  description = "Name of the domain"
  default = "domain"
}

variable "context" {
  type = string
  description = "Name of the context"
  default = "api"
}

variable "env" {
  type = string
  description = "Environment of the resources"
  default = "dev"
}