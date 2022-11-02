aws-cfn-batch-for-slc
=====================

AWS CloudFormation stacks of Batch for serverless HPC

[![Lint](https://github.com/dceoy/aws-cfn-batch-with-s3/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/aws-cfn-batch-with-s3/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone --recurse-submodules git@github.com:dceoy/aws-cfn-batch-with-s3.git
    $ cd aws-cfn-batch-with-s3
    ```

2.  Install [Rain](https://github.com/aws-cloudformation/rain) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Set a Slack client on AWS Chatbot and get the Slack workspace ID. (optional)

4.  Deploy stacks for IAM user groups. (optional)

    ```sh
    $ rain deploy \
        iam-user-groups-for-devops.cfn.yml \
        slhpc-dev-iam-user-groups-for-devops
    ```

5.  Deploy stacks for VPC private subnets and a VPC endpoint for S3.

    ```sh
    $ rain deploy \
        --params ProjectName=slhpc-dev \
        aws-cfn-vpc-for-slc/vpc-private-subnets-and-s3-endpoint.cfn.yml \
        slhpc-dev-vpc-private
    ```

6.  Deploy stacks for S3 buckets, IAM roles, and Batch.

    ```sh
    $ rain deploy \
        s3-buckets-for-batch-io.cfn.yml \
        slhpc-dev-s3-buckets-for-batch-io
    $ rain deploy \
        --params S3StackName=slhpc-dev-s3-buckets-for-batch-io \
        iam-roles-for-batch-services.cfn.yml \
        slhpc-dev-iam-roles-for-batch-services
    $ rain deploy \
        --params IamStackName=slhpc-dev-iam-roles-for-batch-services,VpcStackName=slhpc-dev-vpc-private \
        batch-for-hpc.cfn.yml \
        slhpc-dev-batch-for-hpc
    ```

7.  Deploy stacks for VPC public subnets and a Nat gateway for internet access. (optional)

    ```sh
    $ rain deploy \
        --params VpcStackName=slhpc-dev-vpc-private,ProjectName=slhpc-dev \
        aws-cfn-vpc-for-slc/vpc-public-subnets-and-nat-gateway.cfn.yml \
        slhpc-dev-vpc-public
    ```

8.  Deploy a Chatbot for AWS Step Functions. (optional)

    ```sh
    $ rain deploy \
        chatbot-and-sns-for-stepfunctions.cfn.yml \
        slhpc-dev-chatbot-and-sns-for-stepfunctions
    ```
