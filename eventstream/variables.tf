variable "streaming_lite_resource_group_id" {
    type = string
    description = "Name of the streaming lite resource group id"
}

variable "event_stream_name" {
    type = string
    description = "Name of target Event Stream instance"
}

variable "event_stream_region" {
    type = string
    description = "Region of the target Event Stream instance(us-east, eu-gb, eu-de, jp-tok, au-syd)"
}

variable "event_stream_label"{
    type = list(string)
    description = "User defined tags used by the target Event Stream instance"
}