# Drone CI on GCP with Terraform and Kubernetes

This is a terraform definition with some scripts to make it easy to bootstrap Drone CI into a GKE cluster.

This will expose your Drone CI server in a public IP without TLS. Terraform will output the IP for you.

The scripts can:

 - [x] Enable and disable gcloud services
 - [x] Create and destroy terraform service accounts with editor roles

The terraform definition can provision:

 - [x] GKE cluster
    - [x] Random Master Password Generation
    - [x] Separate managed node pool
        - [x] Using Preemptible Instances
 - [x] GCE External IP Address
 - [x] GCE Persistent Disk to store Drone CI master configuration and data
 - [x] All Kubernetes resources Drone CI needs to run:
    - [x] Namespace `drone`
    - [x] Secret `drone-secrets` with the RPC secret stored
        - [x] Random Secret Generation
    - [x] ConfigMap `drone-config` with all configuration for server and runners
    - [x] Deployment for the Drone Server 
        - [x] Environment Variables loaded from Config Map
        - [x] Environment Variables loaded from Secret
        - [x] Volumes mounted from GCE Persistent Disk
    - [x] Service as an ingress load balancer to the Drone Server
        - [x] With GCE External IP Address Assigned
    - [x] Role for the Drone Runner
    - [x] Role Binding for the Drone Runner
    - [x] Service Account for the Drone Runner
    - [x] A deployment for the Drone Runner
        - [x] With Service Account binded

## Prepare the environment

### Set variables first

```sh
cat > ./variables.tfvars <<EOL
gcloud_region              = "us-central1"
gcloud_zone                = "us-central1-c"
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