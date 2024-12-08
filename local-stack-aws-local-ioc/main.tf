#Create user in IAM
resource "aws_iam_user" "yyy_users" {
  name = "yyy_user1"

  tags = {
    creator = "yyy_user1"
  }
}

resource "aws_iam_access_key" "yyy_users_key" {
  user = aws_iam_user.yyy_users.name  # Reference the IAM user
}

output "access_key_id" {
  value = aws_iam_access_key.yyy_users_key.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.yyy_users_key.secret
  sensitive = true
}

locals {
  yyy_users_keys_csv = "access_key,secret_key\n${aws_iam_access_key.yyy_users_key.id},${aws_iam_access_key.yyy_users_key.secret}"
}

resource "local_file" "yyy_users_keys" {
  content  = local.yyy_users_keys_csv
  filename = "yyy-users-keys.csv"
}

#Create Group in IAM and assciate user
resource "aws_iam_group" "terraform-developers" {
  name = "terraform-developers"
}

resource "aws_iam_group_membership" "yyy_users_membership" {
  name = aws_iam_user.yyy_users.name
  users = [aws_iam_user.yyy_users.name]
  group = aws_iam_group.terraform-developers.name
}

#Create Policy in IAM and attach to group

#rds full
data "aws_iam_policy" "rds_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

data "aws_iam_policy" "s3_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#ec2 custome
data "aws_iam_policy_document" "ec2_instance_actions" {
  statement {
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]

    resources = [
      "arn:aws:ec2:*:*:instance/*",
    ]
  }
}

resource "aws_iam_policy" "ec2_instance_actions" {
  name        = "ec2_instance_actions"
  policy      = data.aws_iam_policy_document.ec2_instance_actions.json
}

resource "aws_iam_group_policy_attachment" "terraform-developers_rds_full_access" {
  policy_arn = data.aws_iam_policy.rds_full_access.arn
  group      = aws_iam_group.terraform-developers.name
}

resource "aws_iam_group_policy_attachment" "terraform-developers_s3_full_access" {
  policy_arn = data.aws_iam_policy.s3_full_access.arn
  group      = aws_iam_group.terraform-developers.name
}

resource "aws_iam_group_policy_attachment" "developers_ec2_instance_actions" {
  policy_arn = aws_iam_policy.ec2_instance_actions.arn
  group      = aws_iam_group.terraform-developers.name
}