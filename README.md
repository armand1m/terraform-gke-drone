# Drone CI on GCP with Terraform and Kubernetes

This is a terraform definition with some scripts to make it easy to bootstrap https://drone.io into a GKE cluster using:

 - GitHub as default VCS
 - `drone-runner-kube` as runner
 - `sqlite` as a database, stored in a GCE Persistent Disk

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

## Next steps

 - [ ] Run workload in different k8s namespace
 - [ ] Enable horizontal and vertical autoscaling

## Installing it

### Setup a Github OAuth Application

Create a Github OAuth Application so you can have a Github Client ID and a Github Client Secret.

<img alt="github-oauth" src="https://github.com/armand1m/terraform-gke-drone/blob/master/.github/drone-oauth-config.png?raw=true" />

### Set terraform variables

Change the region and the zones accordingly.
Also, change it to use your github client id and secrets here.

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

### Create terraform backend GCS

Here we're using GCS to store remote terraform state, so you need to create a bucket and a backend configuration file.

```sh
# This script will output a terraform-state-[hex] bucket name for you
./scripts/create-terraform-state-gcs.sh
```

Get the gcs name and then generate a `./backend.tfvars` file

```sh
cat > ./backend.tfvars <<EOL
bucket  = "terraform-state-[hex]"
prefix  = "production"
EOL
```

### Bring it up

```sh
source ./scripts/_shared.sh

./scripts/enable-gcloud-services.sh
./scripts/create-terraform-service-account.sh

terraform init -backend-config=./backend.tfvars
terraform plan -var-file=./variables.tfvars
terraform apply -var-file=./variables.tfvars
```

### Edit Github OAuth to use generated IP Address

Terraform will provision a Static IP Address for you in GCE and will output it.

It will look like this:

```ini
cluster_endpoint = 34.30.4.746
cluster_node_pools = []
cluster_password = blablablbla
cluster_username = drone-cluster-master
drone_server_external_ip = 32.42.37.14
```

Edit your Github OAuth application to use the `drone_server_external_ip` output.

### Access and enjoy

<img alt="drone-homepage" src="https://github.com/armand1m/terraform-gke-drone/blob/master/.github/drone-homepage.png?raw=true" />

## Tearing it down

```sh
source ./scripts/_shared.sh
terraform destroy -var-file=./variables.tfvars
./scripts/delete-terraform-service-account.sh
./scripts/disable-gcloud-services.sh
```

## Copyright

MIT, Armando Magalhaes, 2020
