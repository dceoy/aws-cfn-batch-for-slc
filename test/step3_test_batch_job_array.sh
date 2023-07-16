#!/usr/bin/env bash

set -eu

PROJECT_NAME="${PROJECT_NAME:-hpc-dev}"
IMAGE_NAME="${IMAGE_NAME:-test-s3-sync}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TEST_S3_BUCKET="${INPUT_S3_URI:-${PROJECT_NAME}-output-${AWS_ACCOUNT_ID}}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-3600}"
BATCH_SUBMIT_JOB_JSON="${BATCH_SUBMIT_JOB_JSON:-batch/date.batch.submit-job.j2.json}"

set +e

echo "PROJECT_NAME:                   ${PROJECT_NAME}"
echo "IMAGE_NAME:                     ${IMAGE_NAME}"
echo "AWS_ACCOUNT_ID:                 ${AWS_ACCOUNT_ID}"
echo "TIMEOUT_SECONDS:                ${TIMEOUT_SECONDS}"
echo "BATCH_SUBMIT_JOB_JSON:          ${BATCH_SUBMIT_JOB_JSON}"

# oneTimeSetUp() {
# }

# oneTimeTearDown() {
#   rm -f tmp.*.json
# }

testBatchJobSubmit() {
  for p in 'fargate' 'ec2'; do
    [[ -f "tmp.${p}-${IMAGE_NAME}.job-definition.output.json" ]] || exit 1
    jdn="$(jq -r '.jobDefinitionName' < "tmp.${p}-${IMAGE_NAME}.job-definition.output.json")"
    jdr="$(jq -r '.revision' < "tmp.${p}-${IMAGE_NAME}.job-definition.output.json")"
    [[ -n "${jdn}" ]] && [[ -n "${jdr}" ]] || exit 1
    jq ".jobDefinition=\"${jdn}:${jdr}\"" < "${BATCH_SUBMIT_JOB_JSON}" \
      | jq ".jobQueue=\"${PROJECT_NAME}-batch-job-queue-${p}-intel-spot\"" \
      | jq ".containerOverrides.command[0]=\"--output-s3=s3://${TEST_S3_BUCKET}/tmp/${jdn}/\"" \
      > "tmp.${jdn}.${BATCH_SUBMIT_JOB_JSON##*/}"
    aws batch submit-job --cli-input-json "file://tmp.${jdn}.${BATCH_SUBMIT_JOB_JSON##*/}" \
      | tee "tmp.${jdn}.${BATCH_SUBMIT_JOB_JSON##*/}.output.json"
    assertEquals 'aws batch submit-job' 0 "${PIPESTATUS[0]}"
  done
}

testBatchJobStatus() {
  end_seconds=$((SECONDS + TIMEOUT_SECONDS))
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
    for i in {0..4}; do
      aws s3 cp \
        "s3://${TEST_S3_BUCKET}/tmp/${p}-${IMAGE_NAME}/date_${i}.txt" \
        "tmp.${p}-${IMAGE_NAME}.date_${i}.txt"
      assertEquals 'aws s3 cp' 0 "${?}"
      assertTrue 'aws s3 cp' "[[ -s 'tmp.${p}-${IMAGE_NAME}.date_${i}.txt' ]]"
    done
  done
}

# shellcheck disable=SC1091
. shunit2
