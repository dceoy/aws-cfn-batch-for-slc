#!/usr/bin/env bash

set -euxo pipefail

IMAGE_NAME='test-s3-sync'
IMAGE_TAG='latest'
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker image rm -f "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}" || :
aws ecr delete-repository --repository-name "${IMAGE_NAME}" --force || :
