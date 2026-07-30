# Created by bootstrap/ - see that directory's README before first init.
terraform {
  backend "s3" {
    bucket         = "acmecorp-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "acmecorp-terraform-locks"
    encrypt        = true
  }
}
