variable "ldbws_token" {
    type = string
} # pass terraform apply -var="ldbws_token=YOUR_TOKEN"

variable "station_crs" {
    type = string
}

variable "clean_bucket" {
    type = string
}