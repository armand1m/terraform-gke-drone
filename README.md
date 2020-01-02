# Drone CI on GCP with Terraform and Kubernetes

This is a terraform definition with some scripts to make it easy to bootstrap Drone CI into a GKE cluster with DNS management included.

It will provision:

 - [x] A GKE cluster with a separatelly managed preemptible node pool
    - [x] Random Master Password Generation
 - [x] A GCE Persistent Disk to store Drone CI master configuration and data
 - [x] A GCP Cloud DNS Managed Zone for the variable `domain_name`
 - [x] A GCP DNS Record Set for the CNAME of your `domain_name`
 - [x] All Kubernetes resources Drone CI needs to run:
    - [x] A namespace `drone`
    - [x] A secret `drone-secrets` with the RPC secret stored
        - [x] Random Secret Generation
    - [x] A config map `drone-config` with all configuration for server and runners
    - [x] A deployment for the Drone Server 
        - [x] Environment Variables loaded from Config Map
        - [x] Environment Variables loaded from Secret
        - [x] Volumes mounted from GCE Persistent Disk
    - [x] A service as an ingress load balancer to the Drone Server
    - [x] A DNS Record Set at `drone.${var.domain_name}` to point to the ingress load balancer.
    - [ ] A deployment for the Drone Runner
    - [ ] Cert Manager for automatic SSL certificate generation

## Prepare the environment

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
gcloud auth login
gcloud config set project [PROJECT-ID]
```

## Bringing it up

```sh
source ./scripts/_shared.sh

./scripts/enable-gcloud-services.sh
./scripts/create-terraform-service-account.sh

terraform init
terraform plan -var-file=./variables.tfvars
terraform apply -var-file=./variables.tfvars
```

## Tearing it down

```sh
source ./scripts/_shared.sh
terraform destroy -var-file=./variables.tfvars
./scripts/delete-terraform-service-account.sh
./scripts/disable-gcloud-services.sh
```

## Copyright

MIT, Armando Magalhaes, 2020