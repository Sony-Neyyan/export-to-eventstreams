variable ibmcloud_api_key {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  default     = ""
}

variable "logging_service_key" {
    type = string
    description = "Service key to connect to the source LogDNA instance"
}

variable "logging_region" {
    type = string
    description = "Region of the LogDNA instance (us-east, eu-gb, eu-de, jp-tok, au-syd)"
    default = "us-south"
}

variable "event_stream_name" {
    type = string
    description = "Name of target Event Stream instance"
}

variable "event_stream_region" {
    type = string
    description = "Region of the target Event Stream instance(us-east, eu-gb, eu-de, jp-tok, au-syd)"
    default = "us-south"
}

variable "event_stream_topic" {
    type = string
    description = "Name of the target event stream topic"
    default = "export_logs"
}

variable "event_stream_resource_group" {
    type = string
    description = "Resource Group name of the target Event Stream instance"
    default = "Default"
}

variable "event_stream_retention" {
    type = number
    description = "Log retention time (between 1 to 30 days) settings for the target Event Stream instance (in days)"
}

variable "buffer_time"{
    type = number
    description = "Buffer time for processing by streaming engine (in minutes) recommended >= 15"
    default = "15"
}