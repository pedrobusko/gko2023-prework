# gko2023-Group 11
GKO 2023 Group 11 - Creating a Confluent Cloud environment for Use Case 1


## Before you get started

Before you get started, you're going to need a few things. 
- Terraform (***obviously***)
- Confluent Cloud account
- AWS account
- Confluent Cloud **Cloud API Key & Secret**
- AWS API Key & Secret (ideally with some kind of admin permission)

If you don't have these things, create and collect them. 

## Getting started

To begin, the absolute first thing you'll need to do is clone this repo. 
```bash
git clone <repo name> && cd <repo name>
```

Next, you should create a secrets file to store you keys and secrets. 
```bash
cat <<EOF > env.sh
export CONFLUENT_CLOUD_API_KEY="<replace>"
export CONFLUENT_CLOUD_API_SECRET="<replace>"
export MONGODB_ATLAS_PUBLIC_KEY="<replace>"
export MONGODB_ATLAS_PRIVATE_KEY="<replace>"
export AWS_ACCESS_KEY_ID="<replace>"
export AWS_SECRET_ACCESS_KEY="<replace>"
export AWS_DEFAULT_REGION="us-east-2"

EOF
```

After copying your secrets into the file (replacing `<replace>`), you should export them to the console.
```bash
source env.sh
```

## Provisioning almost everything

Provisioning should be easy. This example is meant to create an **almost** end-to-end setup of components in AWS and Confluent Cloud (still waiting on the Ksql Query part). To provision everything follow the next few steps. 

Initialize Terraform in the `/terraform` directory.
```bash
terraform init
```

Create a plan.
```bash
terraform plan
```

Apply the whole thing!
```bash
terraform apply -auto-approve
```
> ***Note:*** *the `-auto-approve` flag automagically accepts the implicit plan created by `apply`*. 
Give your configuration some time to create. When it's done, head to the Confluent UI and check out what was provisioned.
