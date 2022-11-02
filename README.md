aws-cfn-batch-with-s3
=====================

AWS CloudFormation stacks for batch processing with I/O to S3 buckets

[![Lint](https://github.com/dceoy/aws-cfn-batch-with-s3/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/aws-cfn-batch-with-s3/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone git@github.com:dceoy/aws-cfn-batch-with-s3.git
    $ cd aws-cfn-batch-with-s3
    ```

2.  Install [Rain](https://github.com/aws-cloudformation/rain) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Set a Slack client on AWS Chatbot and get the Slack workspace ID. (optional)

4.  Deploy stacks for user groups. (optional)

    ```sh
    $ rain deploy iam-user-groups-for-devops.cfn.yml iobatch-prd-iam-user-groups-for-devops
    ```

5.  Deploy stacks for batch environments.

    ```sh
    $ rain deploy s3-buckets-for-batch-io.cfn.yml iobatch-prd-s3-buckets-for-batch-io
    $ rain deploy iam-roles-for-batch-services.cfn.yml iobatch-prd-iam-roles-for-batch-services
    $ rain deploy vpc-with-natgw.cfn.yml iobatch-prd-vpc-with-natgw
    $ rain deploy batch-for-hpc.cfn.yml iobatch-prd-batch-for-hpc
    ```

6.  Deploy a Chatbot for AWS Step Functions. (optional)

    ```sh
    $ rain deploy chatbot-and-sns-for-stepfunctions.cfn.yml iobatch-prd-chatbot-and-sns-for-stepfunctions
    ```
