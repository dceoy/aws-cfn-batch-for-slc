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
        --params ProjectName=slhpc-dev \
        iam-user-groups-for-devops.cfn.yml \
        slhpc-dev-iam-user-groups-for-devops
    ```

5.  Deploy stacks for S3 buckets.

    ```sh
    $ rain deploy \
        --params ProjectName=slhpc-dev \
        aws-cfn-s3-for-io/s3-buckets-for-io.cfn.yml \
        slhpc-dev-s3-buckets-for-io
    ```

6.  Deploy stacks for IAM roles.

    ```sh
    $ rain deploy \
        --params ProjectName=slhpc-dev,S3StackName=slhpc-dev-s3-buckets-for-io \
        iam-roles-for-batch-services.cfn.yml \
        slhpc-dev-iam-roles-for-batch-services
    ```

7.  Deploy stacks for VPC private subnets and VPC endpoints.

    ```sh
    $ rain deploy \
        --params ProjectName=slhpc-dev \
        aws-cfn-vpc-for-slc/vpc-private-subnets-with-endpoints.cfn.yml \
        slhpc-dev-vpc-private-subnets-with-endpoints
    ```

8.  Deploy stacks for Batch.

    ```sh
    $ rain deploy \
        --params ProjectName=slhpc-dev,IamStackName=slhpc-dev-iam-roles-for-batch-services,VpcStackName=slhpc-dev-vpc-private-subnets-with-endpoints \
        batch-for-hpc.cfn.yml slhpc-dev-batch-for-hpc
    ```

9.  Deploy stacks for VPC public subnets and NAT gateways for internet access. (optional)

    ```sh
    $ rain deploy \
        --params ProjectName=slhpc-dev,VpcStackName=slhpc-dev-vpc-private-subnets-with-endpoints \
        aws-cfn-vpc-for-slc/vpc-public-subnets-with-nat-gateway-per-az.cfn.yml \
        slhpc-dev-vpc-public-subnets-with-nat-gateway-per-az
    ```

10. Deploy a Chatbot for AWS Step Functions. (optional)

    ```sh
    $ rain deploy \
        chatbot-and-sns-for-stepfunctions.cfn.yml \
        slhpc-dev-chatbot-and-sns-for-stepfunctions
    ```
