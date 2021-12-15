iobatch
=======

AWS Stack for Batch Processing with I/O to S3 Buckets

[![Lint](https://github.com/dceoy/iobatch/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/iobatch/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone git@github.com:dceoy/iobatch.git
    $ cd iobatch
    ```

2.  Install [Rain](https://github.com/aws-cloudformation/rain) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Set Slack client on AWS Chatbot and get Slack workspace ID.

4.  Deploy stacks for batch environments.

    ```sh
    $ rain deploy cloudformation/iobatch/vpc.yml iobatch-dev-vpc
    $ rain deploy cloudformation/iobatch/s3.yml iobatch-dev-s3
    $ rain deploy cloudformation/iobatch/iam.yml iobatch-dev-iam
    $ rain deploy cloudformation/iobatch/chatbot.yml iobatch-dev-chatbot
    $ rain deploy cloudformation/iobatch/batch.yml iobatch-dev-batch
    ```

5.  Deploy stacks for global configurations. (optional)

    ```sh
    $ rain deploy cloudformation/global/iam.yml global-iam
    ```

6.  Deploy stacks for Amazon GuardDuty. (optional)

    i.    Create IAM roles for CloudFormation StackSets.

    ii.   Create StackSet for all available regions using `cloudformation/global/guardduty.yml`.

    iii.  Deploy a Chatbot stack for GuardDuty.

    ```sh
    $ rain deploy cloudformation/global/chatbot.yml global-chatbot
    ```
