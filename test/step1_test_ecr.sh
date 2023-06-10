#!/usr/bin/env bash

set -eu

IMAGE_NAME="${IMAGE_NAME:-test-s3-sync}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

set +e

echo "IMAGE_NAME:                     ${IMAGE_NAME}"
echo "IMAGE_TAG:                      ${IMAGE_TAG}"
echo "AWS_ACCOUNT_ID:                 ${AWS_ACCOUNT_ID}"
echo "AWS_REGION:                     ${AWS_REGION}"
echo "ECR_REGISTRY:                   ${ECR_REGISTRY}"

oneTimeSetUp() {
  aws ecr delete-repository --repository-name "${IMAGE_NAME}" --force \
    > /dev/null 2>&1
  docker image build --tag "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}" ./ecr
}

# oneTimeTearDown() {
#   docker image rm -f "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
#   aws ecr delete-repository --repository-name "${IMAGE_NAME}" --force
# }

testCreatingEcrRepository() {
  aws ecr create-repository --repository-name "${IMAGE_NAME}"
  assertEquals 'aws ecr create-repository' 0 "${?}"
}

testEcrLogin() {
  aws ecr get-login-password --region "${AWS_REGION}" \
    | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
  ps=("${PIPESTATUS[@]}")
  assertEquals 'aws ecr get-login-password' 0 "${ps[0]}"
  assertEquals 'docker login' 0 "${ps[1]}"
}

testDockerImagePushToEcr() {
  docker image push "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
  assertEquals 'docker image push' 0 "${?}"
  aws ecr describe-images --repository-name "${IMAGE_NAME}" --image-ids imageTag="${IMAGE_TAG}"
  assertEquals 'aws ecr describe-images' 0 "${?}"
}

# shellcheck disable=SC1091
. shunit2
