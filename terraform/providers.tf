terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "4.51.0"
        }
        confluent = {
            source = "confluentinc/confluent"
            version = "1.25.0"
        }
        mongodbatlas = {
            source = "mongodb/mongodbatlas"
        }
    }
}