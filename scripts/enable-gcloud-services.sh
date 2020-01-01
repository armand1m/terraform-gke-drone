source "$(pwd)/scripts/_shared.sh"

echo "Enabling container.googleapis.com.."
gcloud services enable container.googleapis.com

echo "Enabling dns.googleapis.com.."
gcloud services enable dns.googleapis.com
