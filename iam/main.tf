terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.24.0"
    }
  }

}
provider "aws" {
  region  = "us-east-1"
}
resource "aws_s3_bucket" "metrics" {
  bucket = "dev-test-thanos-metrics-prometheus"

  tags = {
    environment = "dev"
  }
}

resource "aws_s3_bucket_acl" "metrics_acl" {
  bucket = aws_s3_bucket.metrics.id
  acl    = "private"
}

resource "aws_iam_policy" "thanos_metrics_policy" {
  name        = "thanos_metrics_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.metrics.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.metrics.bucket}"
        ]
      },
    ]
  })
}

resource "aws_iam_role" "thanos_role" {
  name = "thanos-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "arn:aws:iam::770688751007:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/F81E2B8E1A426AD8093A807FA62BAD12"
        }
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/F81E2B8E1A426AD8093A807FA62BAD12:sub": "system:serviceaccount:platform:thanos-store"
          }
        }
      },
    ]
  })

  tags = {
    environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "thanos_attach" {
  role       = aws_iam_role.thanos_role.name
  policy_arn = aws_iam_policy.thanos_metrics_policy.arn
}