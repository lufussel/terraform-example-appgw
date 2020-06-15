variable "location" {
    description = "The location for resource deployment"
    type        = string

    default     = "uksouth"
}

variable "tags" {
  description   = "A map of tags to assign to the resource."
  type          = map

  default = {
    application = "terraform-testing"
    environment = "development"
    owner       = "lufussel"
    buildagent  = "local"
  }
}