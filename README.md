aws-cfn-batch-for-slc
=====================

AWS CloudFormation stacks of Batch for serverless HPC

[![Lint](https://github.com/dceoy/aws-cfn-batch-for-slc/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/aws-cfn-batch-for-slc/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone --recurse-submodules git@github.com:dceoy/aws-cfn-batch-for-slc.git
    $ cd aws-cfn-batch-for-slc
    ```

2.  Install [Rain](https://github.com/aws-cloudformation/rain) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Set a Slack client on AWS Chatbot and get the Slack workspace ID. (optional)

4.  Deploy stacks for IAM user group stacks. (optional)

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev \
        iam-user-groups-for-devops.cfn.yml \
        hpc-dev-iam-user-groups-for-devops
    ```

5.  Deploy stacks for S3 buckets.

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev \
        aws-cfn-s3-for-io/s3-buckets-with-access-logger.cfn.yml \
        hpc-dev-s3-buckets-with-access-logger
    ```

6.  Deploy stacks for IAM roles.

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev \
        iam-roles-for-batch-services.cfn.yml \
        hpc-dev-iam-roles-for-batch-services
    ```

7.  Deploy stacks for VPC private subnets and VPC endpoints.

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev \
        aws-cfn-vpc-for-slc/vpc-private-subnets-with-gateway-endpoints.cfn.yml \
        hpc-dev-vpc-private-subnets-with-gateway-endpoints
    ```

8.  Deploy stacks for Batch.

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev,IamRoleStackName=hpc-dev-iam-roles-for-batch-services,VpcStackName=hpc-dev-vpc-private-subnets-with-gateway-endpoints \
        batch-environments-and-queues.cfn.yml hpc-dev-batch-environments-and-queues
    ```

9.  Deploy stacks for VPC public subnets and NAT gateways for internet access. (optional)

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev,VpcStackName=hpc-dev-vpc-private-subnets-with-gateway-endpoints \
        aws-cfn-vpc-for-slc/vpc-public-subnets-with-nat-gateway-per-az.cfn.yml \
        hpc-dev-vpc-public-subnets-with-nat-gateway-per-az
    ```

10. Deploy stacks for EFS. (optional)

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev,VpcStackName=hpc-dev-vpc-private-subnets-with-gateway-endpoints \
        aws-cfn-nfs/efs-with-access-point.cfn.yml hpc-dev-efs-with-access-point
    ```

11. Deploy a Chatbot for AWS Step Functions. (optional)

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev \
        sns-with-chatbot-for-stepfunctions.cfn.yml \
        hpc-dev-sns-with-chatbot-for-stepfunctions.cfn.yml
    ```

12. Deploy stacks for Budgets Action. (optional)

    ```sh
    $ rain deploy \
        --params ProjectName=hpc-dev,IamRoleStackName=hpc-dev-iam-roles-for-batch-services,IamGroupStackName=hpc-dev-iam-user-groups-for-devops \
        budgets-action-and-sns-with-chatbot.cfn.yml \
        hpc-dev-budgets-action-and-sns-with-chatbot
    ```

13. Enable ECR image scanning. (optional)

    ```sh
    $ aws ecr put-registry-scanning-configuration \
        --scan-type BASIC \
        --rules '[{"repositoryFilters" : [{"filter":"*","filterType" : "WILDCARD"}], "scanFrequency" : "SCAN_ON_PUSH"}]'
    ```
