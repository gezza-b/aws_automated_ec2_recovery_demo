#
# IAM role and policy for the restore
#

# IAM role
resource "aws_iam_role" "role_restore" {
  name               = "aws-restore-role-2-${local.region}"
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  ]
  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "ec2:StartInstances",
            "ec2:AttachVolume",
            "kms:Encrypt",
            "kms:Decrypt"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "backup:GetRecoveryPointRestoreMetadata",
            "backup:StartRestoreJob",
            "backup:DescribeRestoreJob",
            "backup:ListRestoreJobs",
            "backup:ListRecoveryPointsByResource"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "backup:DescribeBackupVault",
            "backup:PutBackupVaultNotifications",
            "backup:ListRecoveryPointsByBackupVault",
            "backup:GetBackupVaultNotifications",
            "backup:GetBackupVaultAccessPolicy"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:backup:*:${data.aws_caller_identity.current.account_id}:backup-vault:*"
        },
        {
          Action = [
            "iam:GetRole",
            "iam:PassRole"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
        }
      ]
    })
  }
}

# IAM policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "backup.amazonaws.com"
      ]
    }
  }
}
