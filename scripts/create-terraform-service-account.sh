source "$(pwd)/scripts/_shared.sh"

mkdir -p $GCLOUD_CREDENTIALS_FOLDER_PATH

echo "Creating service account $TERRAFORM_SERVICE_ACCOUNT_NAME.."
gcloud iam service-accounts create $TERRAFORM_SERVICE_ACCOUNT_NAME \
    --description="Gives permission to plan and apply changes with terraform." \
    --display-name="$TERRAFORM_SERVICE_ACCOUNT_DISPLAY_NAME"

echo "Setting roles/editor into $TERRAFORM_SERVICE_ACCOUNT_NAME.."
gcloud projects add-iam-policy-binding $PROJECT_NAME \
    --member "serviceAccount:$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com" \
    --role "roles/editor"

echo "Setting roles/storage.admin into $TERRAFORM_SERVICE_ACCOUNT_NAME.."
gcloud projects add-iam-policy-binding $PROJECT_NAME \
    --member "serviceAccount:$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com" \
    --role "roles/storage.admin"

echo "Generating service account key for $TERRAFORM_SERVICE_ACCOUNT_NAME.."
gcloud iam service-accounts keys create $GOOGLE_APPLICATION_CREDENTIALS \
    --iam-account "$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com"