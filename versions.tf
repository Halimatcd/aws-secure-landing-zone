terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "landingzone-terraform-state-955364210974"
    key          = "secure-landing-zone/terraform.tfstate"
    region       = "us-east-1"
    profile      = "landingzone-sso"
    use_lockfile = true
  }
}
