output "kafka_brokers_sasl" {
    value = ibm_event_streams_topic.es_topic.kafka_brokers_sasl
}

output "kafka_topic_name" {
    value = ibm_event_streams_topic.es_topic.name
}

output "service_credential_user" {
    value = ibm_resource_key.resource_key.credentials.user
}

output "service_credential_password" {
    value = ibm_resource_key.resource_key.credentials.password
}