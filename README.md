aws-iobatch
===========

AWS Stack for Batch Processing with I/O to S3 Buckets

[![Lint](https://github.com/dceoy/aws-iobatch/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/aws-iobatch/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone git@github.com:dceoy/aws-iobatch.git
    ```

2.  Install [Rain](https://github.com/aws-cloudformation/rain) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Set Slack client on AWS Chatbot.

4.  Deploy stacks for batch environments.

    ```sh
    $ rain deploy cloudformation/iobatch/iam.yml iobatch-dev-iam
    $ rain deploy cloudformation/iobatch/s3.yml iobatch-dev-s3
    $ rain deploy cloudformation/iobatch/vpc.yml iobatch-dev-vpc
    $ rain deploy cloudformation/iobatch/batch.yml iobatch-dev-batch
    $ rain deploy cloudformation/iobatch/chatbot.yml iobatch-dev-chatbot
    ```
