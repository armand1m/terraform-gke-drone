source "$(pwd)/scripts/_shared.sh"

echo "Deleting $TERRAFORM_SERVICE_ACCOUNT_NAME service account key.."
gcloud iam service-accounts keys delete $GOOGLE_APPLICATION_CREDENTIALS \
    --iam-account "$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com"

echo "Removing editor role from $TERRAFORM_SERVICE_ACCOUNT_NAME.."
gcloud projects remove-iam-policy-binding $PROJECT_NAME \
    --member "serviceAccount:$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com" \
    --role "roles/editor"

echo "Deleting service account $TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com.."
gcloud iam service-accounts delete "$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com"

echo "Deleting folder $GCLOUD_CREDENTIALS_FOLDER_PATH.."
rm -rf $GCLOUD_CREDENTIALS_FOLDER_PATH