# -*- coding: utf-8 -*-
import boto3
import json

# Boto3 clients
backup_client = boto3.client('backup')
ec2_client=boto3.client('ec2')

# Get instance Id
def get_instance_id(event):
    return event["detail"]["instance-id"]

# Get AWS account Id
def get_account_id(context):
    return context.invoked_function_arn.split(":")[4]

# Get AWS region
def get_region(context):
    return context.invoked_function_arn.split(":")[3]

# Restore from the backup vault
def restore_ec2(recovery_point_arn, region, account_id):
    role_arn = f'arn:aws:iam::{account_id}:role/aws-restore-role-2-{region}'
    restore_job_id = backup_client.start_restore_job(
        RecoveryPointArn=recovery_point_arn,
        Metadata={
            'Encrypted' : 'false',
            'InstanceType': 't2.micro',
            'VpcId' : 'vpc-00df06351130c4cb5',
            'SubnetId' : 'subnet-036b1aaf8e5341fbf',
            'SecurityGroups' : 'sg-0edec3a3fd5c7508e'
        },
        IamRoleArn=role_arn,
        ResourceType='EC2'
    )
    return restore_job_id

# Get list of recovery points
def get_recovery_points_by_ec2_arn(ec2_arn):
    return backup_client.list_recovery_points_by_resource(
        MaxResults=120,
        ResourceArn = ec2_arn
    )



def get_tag_ref(app_name, role, backup_plan, name):
    return {
        'app_name': app_name,
        'role': role,
        'backup_plan' : backup_plan,
        'Name' : name
    }

# Returns all meta data of the instance
def get_ec2_tags(instance_id):
    app_name = ""; role = ""; backup_plan = ""; name = ""
    tags = ec2_client.describe_tags(
        Filters=[
            {
                'Name': 'resource-id',
                'Values': [
                    instance_id
                ]
            }
        ],
        MaxResults=10
    )
    for i in tags["Tags"]:
        if i["Key"] == "app_name":
            app_name = i["Value"]
        elif i["Key"] == "role":
            role = i["Value"]
        elif i["Key"] == "backup_plan":
            backup_plan = i["Value"]
        elif i["Key"] == "Name":
            name = i["Value"]
    return get_tag_ref(app_name, role, backup_plan, name)

# Handler
def lambda_handler(event, context):
    region = get_region(context)
    instance_id = get_instance_id(event)
    account_id = get_account_id(context)

    ec2_arn = f'arn:aws:ec2:{region}:{account_id}:instance/{instance_id}'

    # Ideally we add those tags to the recovered instance
    ec2_tags = get_ec2_tags(instance_id)

    recovery_points = get_recovery_points_by_ec2_arn(ec2_arn)

    if (len(recovery_points["RecoveryPoints"]) > 0):
        recovery_point_arn = recovery_points["RecoveryPoints"][1]["RecoveryPointArn"]
        restore_job_id = restore_ec2(recovery_point_arn, region, account_id, )
        # e.g. we could send the restore_job_id to an SNS topic

    return {
        'statusCode': 200,
        'body': json.dumps('Lambda Restore completed')
    }
