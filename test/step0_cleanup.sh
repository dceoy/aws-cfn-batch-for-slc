#!/usr/bin/env bash

set -euxo pipefail

PROJECT_NAME="${PROJECT_NAME:-hpc-dev}"
IMAGE_NAME="${IMAGE_NAME:-test-s3-sync}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
TEST_S3_BUCKET="${INPUT_S3_URI:-${PROJECT_NAME}-output-${AWS_ACCOUNT_ID}}"

docker image rm -f "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}" || :
aws ecr delete-repository --repository-name "${IMAGE_NAME}" --force || :

for p in 'fargate' 'ec2'; do
  aws batch describe-job-definitions --job-definition-name "${p}-${IMAGE_NAME}" \
    | jq '.jobDefinitions[] | select(.status == "ACTIVE").revision' \
    | xargs -t -I{} aws batch deregister-job-definition \
      --job-definition "${p}-${IMAGE_NAME}:{}" || :
  aws s3 rm --recursive "s3://${TEST_S3_BUCKET}/tmp/${p}-${IMAGE_NAME}/" || :
  aws s3api list-object-versions \
    --bucket "${TEST_S3_BUCKET}" \
    --prefix "tmp/${p}-${IMAGE_NAME}/" \
    | jq -rc '.Versions[], .DeleteMarkers[] | .Key, .VersionId' \
    | xargs -L2 bash -xc \
      "aws s3api delete-object --bucket ${TEST_S3_BUCKET} --key \${0} --version-id \${1}" || :
done

rm -f tmp.*
