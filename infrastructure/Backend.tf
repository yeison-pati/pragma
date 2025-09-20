terraform {
  backend "s3" {
    bucket         = "my-pragma-state-bucket"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}