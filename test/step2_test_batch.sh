#!/usr/bin/env bash

set -u

PROJECT_NAME="${PROJECT_NAME:-hpc-dev}"
IMAGE_NAME="${IMAGE_NAME:-test-s3-sync}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BATCH_JOB_ROLE_ARN="${BATCH_JOB_ROLE_ARN:-arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROJECT_NAME}-BatchJobRole}"
BATCH_JOB_EXECUTION_ROLE_ARN="${BATCH_JOB_EXECUTION_ROLE_ARN:-arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROJECT_NAME}-BatchJobExecutionRole}"

echo "PROJECT_NAME:                   ${PROJECT_NAME}"
echo "IMAGE_NAME:                     ${IMAGE_NAME}"
echo "IMAGE_TAG:                      ${IMAGE_TAG}"
echo "AWS_ACCOUNT_ID:                 ${AWS_ACCOUNT_ID}"
echo "AWS_REGION:                     ${AWS_REGION}"
echo "ECR_REGISTRY:                   ${ECR_REGISTRY}"
echo "BATCH_JOB_ROLE_ARN:             ${BATCH_JOB_ROLE_ARN}"
echo "BATCH_JOB_EXECUTION_ROLE_ARN:   ${BATCH_JOB_EXECUTION_ROLE_ARN}"

# oneTimeSetUp() {
# }

# oneTimeTearDown() {
#   for p in 'fargate' 'ec2'; do
#     aws batch describe-job-definitions --job-definition-name "${p}-${IMAGE_NAME}" \
#       | jq '.jobDefinitions[] | select(.status == "ACTIVE").revision' \
#       | sed -e '1d' \
#       | xargs -t -I{} aws batch deregister-job-definition \
#         --job-definition "${p}-${IMAGE_NAME}:{}"
#   done
#   rm -f *.job-definition.json
# }

testRegisterBatchJobDefinition() {
  for p in 'fargate' 'ec2'; do
    jq ".jobDefinitionName=\"${p}-${IMAGE_NAME}\"" < "./batch/${p}.job-definition.j2.json" \
      | jq ".containerProperties.image=\"${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}\"" \
      | jq ".containerProperties.jobRoleArn=\"${BATCH_JOB_ROLE_ARN}\"" \
      | jq ".containerProperties.executionRoleArn=\"${BATCH_JOB_EXECUTION_ROLE_ARN}\"" \
      > "tmp.${IMAGE_NAME}.${p}.job-definition.json"
    aws batch register-job-definition \
      --cli-input-json "file://tmp.${IMAGE_NAME}.${p}.job-definition.json"
    assertEquals 'aws batch register-job-definition' 0 "${?}"
    assertNotNull 'aws batch describe-job-definitions' "$( \
      aws batch describe-job-definitions --job-definition-name "${p}-${IMAGE_NAME}" \
        | jq '.jobDefinitions[] | select(.status == "ACTIVE").revision' \
    )"
  done
}

# shellcheck disable=SC1091
. shunit2
