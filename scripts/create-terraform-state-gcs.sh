source "$(pwd)/scripts/_shared.sh"

BUCKET_NAME="terraform-state-$(openssl rand -hex 16)"

gsutil mb gs://$BUCKET_NAME/
gsutil versioning set on gs://$BUCKET_NAME

echo "Created GCS bucket on name: $BUCKET_NAME"