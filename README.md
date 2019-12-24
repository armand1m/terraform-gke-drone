# Drone CI on GCP with Terraform and Kubernetes

## Prepare env

```sh
# Set env vars
source ./scripts/_shared.sh

# Set the project
./scripts/setup-gcloud-cli.sh

# Enable needed gcloud services
./scripts/enable-gcloud-services.sh

# Create terraform runner service account and store on disk
./scripts/create-runner-service-account.sh

# Initialize terraform plugins
terraform init
```

## Run it

```
terraform plan
terraform apply
```
