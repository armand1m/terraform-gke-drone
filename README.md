# Drone CI on GCP with Terraform and Kubernetes

## Prepare env

### Set variables first

```sh
cat > ./variables.tfvars <<EOL
domain_name                = "your.domain.here"
drone_github_client_id     = "github-client-id"
drone_github_client_secret = "github-client-secret"
EOL
```

### Prepare cloud environment

```sh
# Login gcloud
gcloud auth login

# Set project
gcloud config set project [PROJECT-ID]

# Enable needed gcloud services
./scripts/enable-gcloud-services.sh
```

## Run it

```sh
# Load environment variables
source ./scripts/_shared.sh

# Create terraform runner service account and store it on disk
./scripts/create-terraform-service-account.sh

terraform init
terraform plan -var-file=./variables.tfvars
terraform apply -var-file=./variables.tfvars
```

## Destroy it

```sh
terraform destroy -var-file=./variables.tfvars
./scripts/delete-terraform-service-account.sh
./scripts/disable-gcloud-services.sh
```