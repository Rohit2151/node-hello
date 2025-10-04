#!/usr/bin/env bash

IMAGE=$1
if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image>"
  exit 2
fi

echo "Scanning $IMAGE"
trivy image --exit-code 1 --severity CRITICAL,HIGH "$IMAGE"
