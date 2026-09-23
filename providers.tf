provider "aws" {
  region  = "us-east-1"
  profile = "landingzone-admin"
}

provider "aws" {
  alias  = "log_archive"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::369992802183:role/OrganizationAccountAccessRole"
  }

  profile = "landingzone-admin"
}

provider "aws" {
  alias  = "audit_security"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::746760141143:role/OrganizationAccountAccessRole"
  }

  profile = "landingzone-admin"
}

provider "aws" {
  alias  = "workload_dev"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::100678005500:role/OrganizationAccountAccessRole"
  }

  profile = "landingzone-admin"
}
