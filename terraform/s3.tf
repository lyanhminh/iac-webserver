
resource "aws_s3_bucket" "project1_s3" {
  bucket = "project1-s3"
  acl    = "private"

  tags = {
    Name    = "MinhsProject1-s3"
    Project = var.project_name
  }

  // policy = file("bucket-policy.json")
}
