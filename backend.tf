terraform {
  backend "s3" {
    bucket = "infra-terraform1"
    key    = "infra_state_file"
    region = "ap-south-1"
    profile = "default"
  }
}
