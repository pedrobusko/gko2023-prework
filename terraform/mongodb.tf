resource "mongodbatlas_cluster" "cluster-test" {
  project_id              = "629f891aae746964c9dced0b"
  name                    = "cluster-test-global"

  # Provider Settings "block"
  provider_name = "TENANT"
  backing_provider_name = "AWS"
  provider_region_name = "EU_CENTRAL_1"
  provider_instance_size_name = "M0"
}

resource "mongodbatlas_database_user" "mongodb-user" {
  username           = "mongodb_username"
  password           = "MongoDBVeryLongPassword2023@"
  project_id         = "629f891aae746964c9dced0b"
  auth_database_name = "admin"

  roles {
    role_name     = "dbAdmin"
    database_name = "cluster-test-global"
  }
}