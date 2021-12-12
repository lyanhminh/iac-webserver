variable "project_name" {}

resource "aws_s3_bucket" "project1_s3" {
  bucket = "project1-s3"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true 
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }  
  }

  tags = {
    Name    = "MinhsProject1-s3"
    Project = var.project_name
  }
}
