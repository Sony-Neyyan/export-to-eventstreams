
locals {
    brokers = <<EOF
    %{ for broker in var.kafka_brokers_sasl ~}"${broker}",%{ endfor }
    EOF
}

locals{
    brokers_string = join(", ", slice(split(",", local.brokers), 0, length(split(",", local.brokers))-1))
}

locals{

    user_defined_parameters_for_trigger = <<EOF
        [
    {
        "key": "kafka_brokers_sasl",
        "value": [${local.brokers_string}]
    },
    {
        "key":"user",
        "value": "${var.user_name}"
    },
    {
        "key": "password",
        "value": "${var.password}"
    },
    {
        "key": "topic",
        "value": "${var.topic_name}"
    },
     {
        "key": "logdna_service_key",
        "value": "${var.logging_service_key}"
    },
    {
        "key": "region_name",
        "value": "${var.logging_region}"
    },
    {
        "key": "back_time_in_min",
        "value": "${var.buffer_time}"
    },
    {
        "key": "cron",
        "value": "* * * * *"
    }

]
EOF

    user_defined_parameters_for_action = <<EOF
        [
    {
        "key": "kafka_brokers_sasl",
        "value": [${local.brokers_string}]
    },
    {
        "key":"user",
        "value": "${var.user_name}"
    },
    {
        "key": "password",
        "value": "${var.password}"
    },
    {
        "key": "topic",
        "value": "${var.topic_name}"
    },
     {
        "key": "logdna_service_key",
        "value": "${var.logging_service_key}"
    },
    {
        "key": "region_name",
        "value": "${var.logging_region}"
    },
    {
        "key": "back_time_in_min",
        "value": "${var.buffer_time}"
    }

]
EOF

}

data "ibm_resource_group" "group" {
    name = var.event_stream_resource_group
}

resource "ibm_function_namespace" "namespace" {
   name                = "export_event_streams"
   resource_group_id   = data.ibm_resource_group.group.id
}

resource "ibm_function_action" "action" {
  name = "export_event_streams"
  namespace = ibm_function_namespace.namespace.name

  exec {
    kind = "python:3.7"
    code = file("${path.module}/logdna_streaming_cloud_func.py")
  }

  limits {
    log_size = 10
    memory   = 2048
    timeout  = 600000
  }
 user_defined_parameters = local.user_defined_parameters_for_action
 depends_on = [
  ibm_function_namespace.namespace  ,
 ]
}

resource "ibm_function_trigger" "trigger" {
  name = "export_event_streams_trigger"
  namespace = ibm_function_namespace.namespace.name
  feed {
      name = "/whisk.system/alarms/alarm"
      parameters = local.user_defined_parameters_for_trigger
  }
  user_defined_parameters = local.user_defined_parameters_for_trigger
  depends_on = [
      ibm_function_action.action,
  ]
}

resource "ibm_function_rule" "solution_rule" {
  name         = "export_event_streams_rule"
  namespace    = "export_event_streams"
  trigger_name = "export_event_streams_trigger"
  action_name  = "export_event_streams"
  depends_on = [
      ibm_function_trigger.trigger,
  ]
}