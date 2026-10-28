provider "aws" {
  region  = "us-east-1"
  profile = "landingzone-sso"
}

provider "aws" {
  alias  = "log_archive"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/OrganizationAccountAccessRole"
  }

  profile = "landingzone-sso"
}

provider "aws" {
  alias  = "audit_security"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::333333333333:role/OrganizationAccountAccessRole"
  }

  profile = "landingzone-sso"
}

provider "aws" {
  alias  = "workload_dev"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::444444444444:role/OrganizationAccountAccessRole"
  }

  profile = "landingzone-sso"
}

provider "aws" {
  alias   = "ca_central"
  region  = "ca-central-1"
  profile = "landingzone-sso"
}
