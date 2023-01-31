resource "random_id" "env_display_id" {
    byte_length = 4
}
# ------------------------------------------------------
# ENVIRONMENT
# ------------------------------------------------------
resource "confluent_environment" "env" {
    display_name = "gko-prework-uc1-env-${random_id.env_display_id.hex}"
}
# ------------------------------------------------------
# SCHEMA REGISTRY
# ------------------------------------------------------
data "confluent_schema_registry_region" "sr_region" {
    cloud = "AWS"
    region = "us-east-2"
    package = "ESSENTIALS"
}
resource "confluent_schema_registry_cluster" "sr" {
    package = data.confluent_schema_registry_region.sr_region.package
    environment {
        id = confluent_environment.env.id 
    }
    region {
        id = data.confluent_schema_registry_region.sr_region.id
    }
}
# ------------------------------------------------------
# KAFKA
# ------------------------------------------------------
resource "confluent_kafka_cluster" "basic" {
    display_name = "gko-prework-uc1-cluster"
    availability = "SINGLE_ZONE"
    cloud = "AWS"
    region = "${local.aws_region}"
    basic {}
    environment {
        id = confluent_environment.env.id
    }
}
# ------------------------------------------------------
# TOPICS
# ------------------------------------------------------
resource "confluent_kafka_topic" "products_old" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name         = "products_old"
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
        key = confluent_api_key.app_manager_keys.id
        secret = confluent_api_key.app_manager_keys.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_kafka_topic" "products" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name         = "products"
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
        key = confluent_api_key.app_manager_keys.id
        secret = confluent_api_key.app_manager_keys.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_kafka_topic" "joined_products" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name         = "joined_products"
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
        key = confluent_api_key.app_manager_keys.id
        secret = confluent_api_key.app_manager_keys.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}
# ------------------------------------------------------
# SERVICE ACCOUNTS
# ------------------------------------------------------
resource "confluent_service_account" "app_manager" {
    display_name = "app-manager-sa-${random_id.env_display_id.hex}"
    description = "${local.confluent_description}"
}
resource "confluent_service_account" "ksql" {
    display_name = "ksql-${random_id.env_display_id.hex}"
    description = "${local.confluent_description}"
}
resource "confluent_service_account" "connectors" {
    display_name = "connector-sa-${random_id.env_display_id.hex}"
    description = "${local.confluent_description}"
}
# ------------------------------------------------------
# ROLE BINDINGS
# ------------------------------------------------------
resource "confluent_role_binding" "app_manager_env_admin" {
    principal = "User:${confluent_service_account.app_manager.id}"
    role_name = "EnvironmentAdmin"
    crn_pattern = confluent_environment.env.resource_name
}
resource "confluent_role_binding" "ksql_cluster_admin" {
    principal = "User:${confluent_service_account.ksql.id}"
    role_name = "CloudClusterAdmin"
    crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}
resource "confluent_role_binding" "ksql_sr_resource_owner" {
    principal = "User:${confluent_service_account.ksql.id}"
    role_name = "ResourceOwner"
    crn_pattern = format("%s/%s", confluent_schema_registry_cluster.sr.resource_name, "subject=*")
}
# ------------------------------------------------------
# ACLS
# ------------------------------------------------------
resource "confluent_kafka_acl" "connectors_source_acl_describe_cluster" {
    kafka_cluster {
        id = confluent_kafka_cluster.basic.id
    }
    resource_type = "CLUSTER"
    resource_name = "kafka-cluster"
    pattern_type = "LITERAL"
    principal = "User:${confluent_service_account.connectors.id}"
    operation = "DESCRIBE"
    permission = "ALLOW"
    host = "*"
    rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
    credentials {
        key = confluent_api_key.app_manager_keys.id
        secret = confluent_api_key.app_manager_keys.secret
    }
}
resource "confluent_kafka_acl" "connectors_source_acl_create_topic" {
    kafka_cluster {
        id = confluent_kafka_cluster.basic.id
    }
    resource_type = "TOPIC"
    resource_name = "products"
    pattern_type = "LITERAL"
    principal = "User:${confluent_service_account.connectors.id}"
    operation = "CREATE"
    permission = "ALLOW"
    host = "*"
    rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
    credentials {
        key = confluent_api_key.app_manager_keys.id
        secret = confluent_api_key.app_manager_keys.secret
    }
}
resource "confluent_kafka_acl" "connectors_source_acl_write" {
    kafka_cluster {
        id = confluent_kafka_cluster.basic.id
    }
    resource_type = "TOPIC"
    resource_name = "products"
    pattern_type = "LITERAL"
    principal = "User:${confluent_service_account.connectors.id}"
    operation = "WRITE"
    permission = "ALLOW"
    host = "*"
    rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
    credentials {
        key = confluent_api_key.app_manager_keys.id
        secret = confluent_api_key.app_manager_keys.secret
    }
}
# ------------------------------------------------------
# API KEYS
# ------------------------------------------------------
resource "confluent_api_key" "app_manager_keys" {
    display_name = "app-manager-api-key-${random_id.env_display_id.hex}"
    description = "${local.confluent_description}"
    owner {
        id = confluent_service_account.app_manager.id 
        api_version = confluent_service_account.app_manager.api_version
        kind = confluent_service_account.app_manager.kind
    }
    managed_resource {
        id = confluent_kafka_cluster.basic.id 
        api_version = confluent_kafka_cluster.basic.api_version
        kind = confluent_kafka_cluster.basic.kind
        environment {
            id = confluent_environment.env.id
        }
    }
    depends_on = [
        confluent_role_binding.app_manager_env_admin
    ]
}
resource "confluent_api_key" "schema-registry-api-key" {
  display_name = "schema-registry-api-key-${random_id.env_display_id.hex}"
  description  = "${local.confluent_description}"
  owner {
        id = confluent_service_account.app_manager.id 
        api_version = confluent_service_account.app_manager.api_version
        kind = confluent_service_account.app_manager.kind
  }

  managed_resource {
        id = confluent_schema_registry_cluster.sr.id 
        api_version = confluent_schema_registry_cluster.sr.api_version
        kind = confluent_schema_registry_cluster.sr.kind

    environment {
            id = confluent_environment.env.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_api_key" "ksql_keys" {
    display_name = "ksql-api-key-${random_id.env_display_id.hex}"
    description = "${local.confluent_description}"
    owner {
        id = confluent_service_account.ksql.id 
        api_version = confluent_service_account.ksql.api_version
        kind = confluent_service_account.ksql.kind
    }
    managed_resource {
        id = confluent_kafka_cluster.basic.id 
        api_version = confluent_kafka_cluster.basic.api_version
        kind = confluent_kafka_cluster.basic.kind
        environment {
            id = confluent_environment.env.id
        }
    }
    depends_on = [
        confluent_role_binding.ksql_cluster_admin,
        confluent_role_binding.ksql_sr_resource_owner
    ]
}
resource "confluent_api_key" "connector_keys" {
    display_name = "connectors-api-key-${random_id.env_display_id.hex}"
    description = "${local.confluent_description}"
    owner {
        id = confluent_service_account.connectors.id 
        api_version = confluent_service_account.connectors.api_version
        kind = confluent_service_account.connectors.kind
    }
    managed_resource {
        id = confluent_kafka_cluster.basic.id 
        api_version = confluent_kafka_cluster.basic.api_version
        kind = confluent_kafka_cluster.basic.kind
        environment {
            id = confluent_environment.env.id
        }
    }
    depends_on = [
        confluent_kafka_acl.connectors_source_acl_create_topic,
        confluent_kafka_acl.connectors_source_acl_write
    ]
}
# ------------------------------------------------------
# KSQL
# ------------------------------------------------------
resource "confluent_ksql_cluster" "ksql_cluster" {
    display_name = "ksql-cluster-${random_id.env_display_id.hex}"
    csu = 1
    environment {
        id = confluent_environment.env.id
    }
    kafka_cluster {
        id = confluent_kafka_cluster.basic.id
    }
    credential_identity {
        id = confluent_service_account.ksql.id
    }
    depends_on = [
        confluent_role_binding.ksql_cluster_admin,
        confluent_role_binding.ksql_sr_resource_owner,
        confluent_api_key.ksql_keys,
        confluent_schema_registry_cluster.sr
    ]
}
# ------------------------------------------------------
# CONNECT
# ------------------------------------------------------
#resource "confluent_connector" "rabbitmq_products" {
#    environment {
#        id = confluent_environment.env.id 
#    }
#    kafka_cluster {
#        id = confluent_kafka_cluster.basic.id
#    }
#    status = "RUNNING"
#    config_sensitive = {
#        "rabbitmq.username": "ExampleUser",
#        "rabbitmq.password": "MindTheGapLongPassword",
#    }
#    config_nonsensitive = {
#        "connector.class": "RabbitMQSource",
#        "name": "RabbitMQSourceConnector_0",
#        "kafka.auth.mode": "KAFKA_API_KEY",
#        "kafka.api.key": "${confluent_api_key.app_manager_keys.id}",
#        "kafka.api.secret": "${confluent_api_key.app_manager_keys.secret}",
#        "kafka.topic.bootstrap.servers": "${confluent_kafka_cluster.basic.bootstrap_endpoint}",
#        "kafka.topic": "products_old",
        #"rabbitmq.host": "${aws_mq_broker.rabbitmq.instances.0.ip_address}",
        #"rabbitmq.host": "${aws_mq_broker.rabbitmq.instances.0.endpoints.0}",
#        "rabbitmq.host": "b-515097c8-4b03-4dde-8c7c-2c865c7d25db.mq.eu-central-1.amazonaws.com",
#        "rabbitmq.port": "5671",
#        "rabbitmq.queue": "products_queue",
#        "tasks.max": "1"
#    }
#    depends_on = [
#        confluent_kafka_acl.connectors_source_acl_create_topic,
#        confluent_kafka_acl.connectors_source_acl_write,
#        confluent_api_key.connector_keys,
#    ]
#}
resource "confluent_connector" "activemq_products" {
    environment {
        id = confluent_environment.env.id 
    }
    kafka_cluster {
        id = confluent_kafka_cluster.basic.id
    }
    status = "RUNNING"
    config_sensitive = {
        "activemq.username": "ExampleUser",
        "activemq.password": "MindTheGapLongPassword",
    }
    config_nonsensitive = {
        "connector.class": "ActiveMQSource",
        "name": "ActiveMQSourceConnector_0",
        "kafka.auth.mode": "KAFKA_API_KEY",
        "kafka.api.key": "${confluent_api_key.app_manager_keys.id}",
        "kafka.api.secret": "${confluent_api_key.app_manager_keys.secret}",
        "kafka.topic": "products_old",
        "output.data.format": "AVRO",
        "activemq.url": "${aws_mq_broker.activemq.instances.0.endpoints.0}",
        "jms.destination.name": "products_queue",
        "jms.destination.type": "queue",
        "max.poll.duration": "60000",
        "character.encoding": "UTF-8",
        "jms.subscription.durable": "false",
        "tasks.max": "1"
    }
    depends_on = [
        confluent_kafka_acl.connectors_source_acl_create_topic,
        confluent_kafka_acl.connectors_source_acl_write,
        confluent_api_key.connector_keys,
    ]
}

resource "confluent_connector" "mongodb_products" {
    environment {
        id = confluent_environment.env.id 
    }
    kafka_cluster {
        id = confluent_kafka_cluster.basic.id
    }
    status = "RUNNING"
    config_sensitive = {
        "connection.user": "mongodb_username",
        "connection.password": "****************************",
    }
    config_nonsensitive = {
        "connector.class": "MongoDbAtlasSink",
        "name": "MongoDbAtlasSinkConnector_0",
        "input.data.format": "AVRO",
        "cdc.handler": "None",
        "delete.on.null.values": "false",
        "max.batch.size": "0",
        "bulk.write.ordered": "true",
        "rate.limiting.timeout": "0",
        "rate.limiting.every.n": "0",
        "write.strategy": "DefaultWriteModelStrategy",
        "kafka.auth.mode": "KAFKA_API_KEY",
        "kafka.api.key": "${confluent_api_key.app_manager_keys.id}",
        "kafka.api.secret": "${confluent_api_key.app_manager_keys.secret}",
        "topics": "joined_products",
        "connection.host": "${mongodbatlas_cluster.cluster-test.mongo_uri}",
        "database": "cluster-test-global",
        "doc.id.strategy": "BsonOidStrategy",
        "doc.id.strategy.overwrite.existing": "false",
        "document.id.strategy.uuid.format": "string",
        "key.projection.type": "none",
        "value.projection.type": "none",
        "namespace.mapper.class": "DefaultNamespaceMapper",
        "namespace.mapper.error.if.invalid": "false",
        "server.api.deprecation.errors": "false",
        "server.api.strict": "false",
        "max.num.retries": "3",
        "retries.defer.timeout": "5000",
        "timeseries.timefield.auto.convert": "false",
        "timeseries.timefield.auto.convert.date.format": "yyyy-MM-dd[['T'][ ]][HH:mm:ss[[.][SSSSSS][SSS]][ ]VV[ ]'['VV']'][HH:mm:ss[[.][SSSSSS][SSS]][ ]X][HH:mm:ss[[.][SSSSSS][SSS]]]",
        "timeseries.timefield.auto.convert.locale.language.tag": "en",
        "timeseries.expire.after.seconds": "0",
        "ts.granularity": "None",
        "tasks.max": "1"
  }
    depends_on = [
        confluent_kafka_acl.connectors_source_acl_create_topic,
        confluent_kafka_acl.connectors_source_acl_write,
        confluent_api_key.connector_keys,
    ]
}