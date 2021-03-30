variable "event_stream_retention" {
    type = number
    description = "Event retention time of the streaming lite in days"
}

variable "event_stream_name" {
    type = string
    description = "Name of target Event Stream instance"
}

variable "event_stream_topic" {
    type = string
    description = "Name of the event stream instance topic"
}

variable "streaming_lite_id" {
    type = string
    description = "event stream instance id"
}