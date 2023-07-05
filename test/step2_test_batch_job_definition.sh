#!/usr/bin/env bash

set -eu

PROJECT_NAME="${PROJECT_NAME:-hpc-dev}"
IMAGE_NAME="${IMAGE_NAME:-test-s3-sync}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BATCH_JOB_ROLE_ARN="${BATCH_JOB_ROLE_ARN:-arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROJECT_NAME}-BatchJobRole}"
BATCH_JOB_EXECUTION_ROLE_ARN="${BATCH_JOB_EXECUTION_ROLE_ARN:-arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PROJECT_NAME}-BatchJobExecutionRole}"
AWSLOGS_GROUP="/aws/batch/${PROJECT_NAME}-batch-job"
efs_ap_json="$( \
  aws efs describe-access-points \
    | jq ".AccessPoints[] | select(.Name == \"${PROJECT_NAME}-efs-accesspoint\")" \
)"
EFS_FS_ID="$(echo "${efs_ap_json}" | jq -r '.FileSystemId')"
EFS_AP_ID="$(echo "${efs_ap_json}" | jq -r '.AccessPointId')"

set +e

echo "PROJECT_NAME:                   ${PROJECT_NAME}"
echo "IMAGE_NAME:                     ${IMAGE_NAME}"
echo "IMAGE_TAG:                      ${IMAGE_TAG}"
echo "AWS_ACCOUNT_ID:                 ${AWS_ACCOUNT_ID}"
echo "AWS_REGION:                     ${AWS_REGION}"
echo "ECR_REGISTRY:                   ${ECR_REGISTRY}"
echo "BATCH_JOB_ROLE_ARN:             ${BATCH_JOB_ROLE_ARN}"
echo "BATCH_JOB_EXECUTION_ROLE_ARN:   ${BATCH_JOB_EXECUTION_ROLE_ARN}"
echo "EFS_FS_ID:                      ${EFS_FS_ID}"
echo "EFS_AP_ID:                      ${EFS_AP_ID}"

# oneTimeSetUp() {
# }

# oneTimeTearDown() {
#   for p in 'fargate' 'ec2'; do
#     aws batch describe-job-definitions --job-definition-name "${p}-${IMAGE_NAME}" \
#       | jq '.jobDefinitions[] | select(.status == "ACTIVE").revision' \
#       | xargs -t -I{} aws batch deregister-job-definition \
#         --job-definition "${p}-${IMAGE_NAME}:{}"
#     aws s3 rm --recursive "s3://${TEST_S3_BUCKET}/tmp/${p}-${IMAGE_NAME}/"
#   done
#   rm -f tmp.*.json
# }

testBatchJobDefinition() {
  for p in 'fargate' 'ec2'; do
    jdn="${p}-${IMAGE_NAME}"
    jq ".jobDefinitionName=\"${jdn}\"" < "./batch/${p}.job-definition.j2.json" \
      | jq ".containerProperties.image=\"${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}\"" \
      | jq ".containerProperties.jobRoleArn=\"${BATCH_JOB_ROLE_ARN}\"" \
      | jq ".containerProperties.executionRoleArn=\"${BATCH_JOB_EXECUTION_ROLE_ARN}\"" \
      | jq ".containerProperties.volumes[0].efsVolumeConfiguration.fileSystemId=\"${EFS_FS_ID}\"" \
      | jq ".containerProperties.volumes[0].efsVolumeConfiguration.authorizationConfig.accessPointId=\"${EFS_AP_ID}\"" \
      | jq ".containerProperties.logConfiguration.options.\"awslogs-group\"=\"${AWSLOGS_GROUP}\"" \
      | jq ".containerProperties.logConfiguration.options.\"awslogs-stream-prefix\"=\"${jdn}\"" \
      | jq ".tags.ProjectName=\"${PROJECT_NAME}\"" \
      > "tmp.${jdn}.job-definition.json"
    aws batch register-job-definition \
      --cli-input-json "file://tmp.${jdn}.job-definition.json" \
      | tee "tmp.${jdn}.job-definition.output.json"
    assertEquals 'aws batch register-job-definition' 0 "${PIPESTATUS[0]}"
    assertNotNull 'aws batch describe-job-definitions' "$( \
      jq '.revision' < "tmp.${jdn}.job-definition.output.json" \
        | xargs -I{} aws batch describe-job-definitions --job-definitions \
          "arn:aws:batch:${AWS_REGION}:${AWS_ACCOUNT_ID}:job-definition/${jdn}:{}" \
        | jq '.jobDefinitions[] | select(.status == "ACTIVE")' \
    )"
  done
}

# shellcheck disable=SC1091
. shunit2
