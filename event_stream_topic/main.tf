locals {
  retension_period_in_ms = format("%d", (var.event_stream_retention * 86400000))
}

resource "ibm_resource_key" "resource_key" {
  name                 = "myresourcekey"
  role                 = "Writer"
  resource_instance_id = var.streaming_lite_id
  
  //User can increase timeouts
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "ibm_event_streams_topic" "es_topic" {
  resource_instance_id = var.streaming_lite_id
  name                 = var.event_stream_topic
  partitions           = 1
}