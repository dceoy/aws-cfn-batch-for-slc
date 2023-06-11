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
TEST_S3_BUCKET="${INPUT_S3_URI:-${PROJECT_NAME}-output-${AWS_ACCOUNT_ID}}"
WAIT_SECONDS="${WAIT_SECONDS:-3600}"
BATCH_SUBMIT_JOB_JSON="${BATCH_SUBMIT_JOB_JSON:-batch/curl.batch.submit-job.j2.json}"

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
#       | xargs -t -I{} aws batch deregister-job-definition \
#         --job-definition "${p}-${IMAGE_NAME}:{}"
#     aws s3 rm --recursive "s3://${TEST_S3_BUCKET}/tmp/${p}-${IMAGE_NAME}/"
#   done
#   rm -f *.job-definition.json
# }

testBatchJobDefinition() {
  for p in 'fargate' 'ec2'; do
    jdn="${p}-${IMAGE_NAME}"
    jq ".jobDefinitionName=\"${jdn}\"" < "./batch/${p}.job-definition.j2.json" \
      | jq ".containerProperties.image=\"${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}\"" \
      | jq ".containerProperties.jobRoleArn=\"${BATCH_JOB_ROLE_ARN}\"" \
      | jq ".containerProperties.executionRoleArn=\"${BATCH_JOB_EXECUTION_ROLE_ARN}\"" \
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

testBatchJobSubmit() {
  for p in 'fargate' 'ec2'; do
    if [[ "${p}" == 'ec2' ]]; then
      job_queue="${PROJECT_NAME}-batch-job-queue-${p}-intel-spot"
    else
      job_queue="${PROJECT_NAME}-batch-job-queue-${p}-spot"
    fi
    jdn="$(jq -r '.jobDefinitionName' < "tmp.${p}-${IMAGE_NAME}.job-definition.output.json")"
    jdr="$(jq -r '.revision' < "tmp.${p}-${IMAGE_NAME}.job-definition.output.json")"
    [[ -n "${jdn}" ]] && [[ -n "${jdr}" ]] || exit 1
    jq ".jobDefinition=\"${jdn}:${jdr}\"" < "${BATCH_SUBMIT_JOB_JSON}" \
      | jq ".jobQueue=\"${job_queue}\"" \
      | jq ".containerOverrides.command[0]=\"--output-s3=s3://${TEST_S3_BUCKET}/tmp/${jdn}/\"" \
      > "tmp.${jdn}.${BATCH_SUBMIT_JOB_JSON##*/}"
    aws batch submit-job --cli-input-json "file://tmp.${jdn}.${BATCH_SUBMIT_JOB_JSON##*/}" \
      | tee "tmp.${jdn}.${BATCH_SUBMIT_JOB_JSON##*/}.output.json"
    assertEquals 'aws batch submit-job' 0 "${PIPESTATUS[0]}"
  done
}

testBatchJobStatus() {
  end_seconds=$((SECONDS + WAIT_SECONDS))
  for p in 'fargate' 'ec2'; do
    ji=$(jq -r '.jobId' < "tmp.${p}-${IMAGE_NAME}.${BATCH_SUBMIT_JOB_JSON##*/}.output.json")
    [[ -n "${ji}" ]] || exit 1
    js=''
    while [[ ${SECONDS} -lt ${end_seconds} ]]; do
      aws batch describe-jobs --jobs "${ji}" > "tmp.${ji}.batch.describe-jobs.output.json"
      js=$(jq -r '.jobs[0].status' < "tmp.${ji}.batch.describe-jobs.output.json")
      [[ -n "${js}" ]] || exit 1
      if [[ "${js}" == 'SUCCEEDED' ]] || [[ "${js}" == 'FAILED' ]]; then
        break
      fi
      sleep 10
    done
    assertEquals 'aws batch describe-jobs' 'SUCCEEDED' "${js}"
  done
}

testBatchJobOutput() {
  for p in 'fargate' 'ec2'; do
    aws s3 cp \
      "s3://${TEST_S3_BUCKET}/tmp/${p}-${IMAGE_NAME}/global_ip.txt" \
      "tmp.${p}-${IMAGE_NAME}.global_ip.txt"
    assertEquals 'aws s3 cp' 0 "${?}"
    assertTrue 'aws s3 cp' "[[ -s 'tmp.${p}-${IMAGE_NAME}.global_ip.txt' ]]"
  done
}

# shellcheck disable=SC1091
. shunit2
