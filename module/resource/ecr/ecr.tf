provider "aws" {
  region = "us-east-1"
}

resource "aws_ecrpublic_repository" "container_registry" {
    repository_name = var.registry_name
    tags = {
        Name = var.registry_name
        ManagedBy = "CY-Terraform"
        Environment = var.environment
    }
}



