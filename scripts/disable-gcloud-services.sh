source "$(pwd)/scripts/_shared.sh"

echo "Disabling container.googleapis.com.."
gcloud services disable container.googleapis.com

echo "Disabling dns.googleapis.com.."
gcloud services disable dns.googleapis.com
