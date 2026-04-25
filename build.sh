#!/bin/bash

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="dotfiles-dev"
DOCKERFILE_PATH="$SCRIPT_ROOT/Dockerfile"
CONTAINER_SOURCE_ROOT="/home/ben/source"
CONTAINER_WORKDIR="/home/ben"

docker_build_flag="false"
docker_run_flag="false"
docker_image_tag="local"

function print_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --docker-build          Build the Docker image"
  echo "  --docker-run            Build and run the Docker image"
  echo "  --docker-tag <tag>      Specify the Docker image tag (default: local)"
  echo "  -h, --help              Show this help message"
  printf "\n\n"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --docker-build) docker_build_flag="true" ;;
    --docker-run) docker_run_flag="true" ;;
    --docker-tag) docker_image_tag="$2"; shift ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
  esac
  shift
done

function print_stage {
  local stage_name="$1"
  echo ""
  echo "=========================================="
  echo "Starting stage: $stage_name"
  echo "=========================================="
  echo ""
}

function docker_image_name {
  echo "$PROJECT_NAME:$docker_image_tag"
}

function build_docker_image {
  print_stage "Building Docker Image"

  docker build \
    -f "$DOCKERFILE_PATH" \
    -t "$(docker_image_name)" \
    "$SCRIPT_ROOT"

  if [[ "$?" -ne 0 ]]; then
    printf "\nFailed to build Docker image\n"
    exit 1
  else
    printf "\nSuccessfully built Docker image %s\n" "$(docker_image_name)"
  fi
}

function run_docker_image {
  print_stage "Running Docker Image"

  local docker_tty_args=()
  if [[ -t 0 && -t 1 ]]; then
    docker_tty_args=("-it")
  fi

  docker run --rm "${docker_tty_args[@]}" \
    -v "$CONTAINER_SOURCE_ROOT" \
    -w "$CONTAINER_WORKDIR" \
    "$(docker_image_name)"

  if [[ "$?" -ne 0 ]]; then
    printf "\nDocker run failed\n"
    exit 1
  fi
}

if [[ "$docker_build_flag" != "true" && "$docker_run_flag" != "true" ]]; then
  print_usage
  exit 1
fi

if [[ "$docker_build_flag" == "true" || "$docker_run_flag" == "true" ]]; then
  build_docker_image
fi

if [[ "$docker_run_flag" == "true" ]]; then
  run_docker_image
fi
