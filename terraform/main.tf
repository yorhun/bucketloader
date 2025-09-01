# Configure the Google Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# GCS bucket for downloaded files
resource "google_storage_bucket" "downloads" {
  name     = var.bucket_name
  location = var.region
  versioning {
    enabled = true
  }
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",       # for Cloud Functions 2nd gen
    "artifactregistry.googleapis.com", # commonly needed for 2nd gen
    "run.googleapis.com",              # Cloud Run backend for Cloud Functions 2nd gen
  ])
  
  service = each.value
  disable_dependent_services = false
  disable_on_destroy = false
}

# Set permissions - IAM
resource "google_project_iam_member" "cloudbuild_artifactregistry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_cloudfunctions" {
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_serviceaccountuser" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}
# GCS bucket for function source code
resource "google_storage_bucket" "functions_bucket" {
  name     = "${var.bucket_name}-function-source"
  location = var.region
}

# Service account for Cloud Function
resource "google_service_account" "url_downloader" {
  account_id   =  "${var.service_account_id}"
  display_name = "URL to GCS Downloader Function"
  description  = "Service account for Cloud Function that downloads files from URLs to GCS"
}

# Grant storage permissions to service account
resource "google_storage_bucket_iam_member" "downloader_bucket_access" {
  bucket = google_storage_bucket.downloads.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.url_downloader.email}"
}

# Zip path
variable "source_zip_path" {
  description = "Path to the function source ZIP file"
  type        = string
  default     = "./function-source.zip"
}

# Upload function source to GCS
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = var.source_zip_path
}

# Cloud Function for URL to GCS transfer
resource "google_cloudfunctions2_function" "url_downloader" {
  name     = "url-downloader"
  location = var.region
  depends_on = [google_project_service.required_apis]
  
  build_config {
    runtime     = "python313"
    entry_point = "download_url_to_gcs"
    
    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    available_memory      = var.function_memory
    timeout_seconds       = 540    # unit: seconds
    service_account_email = google_service_account.url_downloader.email
    
    environment_variables = {
      BUCKET_NAME = google_storage_bucket.downloads.name
    }
  }
}

# Outputs
output "function_url" {
  description = "URL of the Cloud Function"
  value       = google_cloudfunctions2_function.url_downloader.service_config[0].uri
}

output "bucket_name" {
  description = "Name of the downloads bucket"
  value       = google_storage_bucket.downloads.name
}