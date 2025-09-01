# Variables
variable "google_credentials_path" {
  description = "The GCP credentials path"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_number" {
  type    = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "bucket_name" {
  description = "GCS Bucket name for downloads"
  type        = string
}

variable "function_memory" {
  description = "Memory allocated for cloud function"
  type        = string
}

variable "service_account_id" {
  description = "ID for the Cloud Function service account"
  type        = string
  default     = "url-downloader-cf"
}
