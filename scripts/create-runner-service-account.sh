source "$(pwd)/scripts/_shared.sh"

mkdir -p $GCLOUD_CREDENTIALS_FOLDER_PATH

gcloud iam service-accounts create $TERRAFORM_SERVICE_ACCOUNT_NAME \
    --description="Gives permission to plan and apply changes with terraform." \
    --display-name=$TERRAFORM_SERVICE_ACCOUNT_DISPLAY_NAME

gcloud projects add-iam-policy-binding $PROJECT_NAME \
    --member "serviceAccount:$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com" \
    --role "roles/editor"

gcloud iam service-accounts keys create $GOOGLE_APPLICATION_CREDENTIALS \
    --iam-account "$TERRAFORM_SERVICE_ACCOUNT_NAME@$PROJECT_NAME.iam.gserviceaccount.com"