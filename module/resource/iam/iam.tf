resource "aws_iam_user" "ec2_ecr_manager" {
    name = "EC2_ECR_manager"
}

resource "aws_iam_user" "s3_cdn_manager" {
    name = "S3_CDN_manager"
}

resource "aws_iam_user_policy_attachment" "ec2_full_access" {
    user = aws_iam_user.ec2_ecr_manager.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}


resource "aws_iam_user_policy_attachment" "ecr_public_full_access" {
    user = aws_iam_user.ec2_ecr_manager.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicFullAccess"
}

resource "aws_iam_access_key" "access_key_for_ecr_ec2" {
    user = aws_iam_user.ec2_ecr_manager.name
}

resource "aws_iam_user_policy_attachment" "s3_full_access" {
    user = aws_iam_user.s3_cdn_manager.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "cdn_full_access" {
    user = aws_iam_user.s3_cdn_manager.name
    policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

resource "aws_iam_access_key" "access_key_for_s3_cdn" {
    user = aws_iam_user.s3_cdn_manager.name
}

resource "local_file" "ecr_ec2_keys" {
    filename = "ecr_ec2_keys.txt"
    content  = <<EOF
Access Key ID: ${aws_iam_access_key.access_key_for_ecr_ec2.id}
Secret Access Key: ${aws_iam_access_key.access_key_for_ecr_ec2.secret}
EOF
}


resource "local_file" "s3_cdn_keys" {
    filename = "s3_cdn_keys.txt"
    content  = <<EOF
Access Key ID: ${aws_iam_access_key.access_key_for_s3_cdn.id}
Secret Access Key: ${aws_iam_access_key.access_key_for_s3_cdn.secret}
EOF
}

