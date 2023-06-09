#!/usr/bin/env bash

set -u

IMAGE_NAME='test-s3-sync'
IMAGE_TAG='latest'
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

oneTimeSetUp() {
  # aws ecr delete-repository --repository-name "${IMAGE_NAME}" --force || :
  docker image build --tag "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}" ./ecr
}

# oneTimeTearDown() {
#   docker image rm -f "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
#   aws ecr delete-repository --repository-name "${IMAGE_NAME}" --force
# }

testCreateEcrRepository() {
  aws ecr create-repository --repository-name "${IMAGE_NAME}"
  assertEquals 0 "${?}"
}

testPushDockerImageToEcr() {
  aws ecr get-login-password --region "${AWS_REGION}" \
    | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
  docker image push "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
  aws ecr describe-images --repository-name "${IMAGE_NAME}" --image-ids imageTag="${IMAGE_TAG}"
  assertEquals 0 "${?}"
}

# shellcheck disable=SC1091
. shunit2
