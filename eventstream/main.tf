resource "ibm_resource_instance" "es_instance" {
  name              = var.event_stream_name
  service           = "messagehub"
  plan              = "enterprise-3nodes-2tb"
  location          = var.event_stream_region
  resource_group_id = var.streaming_lite_resource_group_id
  tags =  var.event_stream_label

  parameters = {
    service-endpoints  = "public"
    throughput   = "150"  
    storage_size = "2048"
  }
  timeouts {
    create = "3h" 
    update = "3h"
    delete = "3h"
  }
}
