resource "random_string" "random" {
    length = 8
    upper = false
    special = false
}

resource "aws_s3_bucket" "for_static_site" {
    bucket = "bucket-for-static-site-${random_string.random.result}"
    
    tags = {
        Name = "bucket for static site"
        ManagedBy = "CY-Terraform"
        Environment = var.environment
    }
}

# resource "aws_s3_bucket_policy" "policy" {
#     bucket = aws_s3_bucket.for_static_site.id

#     policy = jsonencode({
#         Version = "2012-10-17",
#         Statement = [
#             {
#                 Action = "s3:GetObject"
#                 Effect = "Allow",
#                 Principal = "*",
#                 Resource = "${aws_s3_bucket.for_static_site.arn}/*"
#             },
#             {
#                 Action = "s3:*",
#                 Effect = "Allow",
#                 Principal = {
#                     AWS = "${var.iam_for_s3}"
#                 },
#                 Resource = "${aws_s3_bucket.for_static_site.arn}/*"
#             }
#         ]
#     })
# }

resource "aws_s3_bucket_website_configuration" "website_config" {
    bucket = aws_s3_bucket.for_static_site.id
    
    index_document {
        suffix = "index.html"
    }
    
    error_document {
        key = "index.html"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "name" {
    bucket = aws_s3_bucket.for_static_site.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
            kms_master_key_id = ""
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_cors_configuration" "cors_rule" {
    bucket = aws_s3_bucket.for_static_site.id
    
    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT", "GET"]
        allowed_origins = [
        "http://localhost:5173",
        "http://${aws_s3_bucket.for_static_site.bucket}.s3-website.ap-northeast-2.amazonaws.com"
        ]
        max_age_seconds = 0
    }
}