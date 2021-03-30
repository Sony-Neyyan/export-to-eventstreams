variable "logging_region" {
    type = string
    description = "Region of the LogDNA instance (us-east, eu-gb, eu-de, jp-tok, au-syd)"
}

variable "event_stream_resource_group" {
    type = string
    description = "Resource Group name of the target Event Stream instance"
}

variable "buffer_time"{
    type = number
    description = "Buffer time for processing by streaming engine (in minutes)"
}

variable "logging_service_key" {
    type = string
    description = "Service key to connect to the source LogDNA instance"
}

variable "topic_name" {
    type = string
    description = "Kafka topic name"
}

variable "password" {
    type = string
    description = "service credential password of the event stream instance"
}

variable "user_name" {
    type = string
    description = "service credential user name of the event stream instance"
}

variable "kafka_brokers_sasl" { 
    description = "kafka_brokers_sasl"
}
