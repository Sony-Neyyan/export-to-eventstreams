data "ibm_resource_group" "group" {
    name = var.event_stream_resource_group
}

module "mod_eventstream_instance" {
    source = "./eventstream"
    streaming_lite_resource_group_id = data.ibm_resource_group.group.id
    event_stream_name = var.event_stream_name
    event_stream_region = var.event_stream_region
    event_stream_label = []
    count                 = 0
}

data "ibm_resource_instance" "eventstream_instance" {
  name              = var.event_stream_name
  location          = var.event_stream_region
  resource_group_id = data.ibm_resource_group.group.id
  service           = "messagehub"
}

module "mod_eventstream_topic" {
    source = "./event_stream_topic"
    streaming_lite_id = data.ibm_resource_instance.eventstream_instance.id
    event_stream_name = var.event_stream_name
    event_stream_retention = var.event_stream_retention
    event_stream_topic = var.event_stream_topic
    depends_on = [data.ibm_resource_instance.eventstream_instance,]
}

module "mod_cloudfunction" {
  source = "./cloudfunctions"
  event_stream_resource_group = var.event_stream_resource_group
  logging_region = var.logging_region
  buffer_time = var.buffer_time
  logging_service_key = var.logging_service_key
  topic_name = module.mod_eventstream_topic.kafka_topic_name
  password = module.mod_eventstream_topic.service_credential_password
  user_name = module.mod_eventstream_topic.service_credential_user
  kafka_brokers_sasl = module.mod_eventstream_topic.kafka_brokers_sasl
  depends_on = [ module.mod_eventstream_topic, ]
}
