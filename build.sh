#!/bin/bash

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_SOURCE_ROOT="/home/ben/source"
CONTAINER_WORKDIR="/home/ben"
SUPPORTED_IMAGES=("ubuntu" "arch")

docker_build_flag="false"
docker_run_flag="false"
docker_image_tag="local"
selected_images=()

function print_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --docker-build          Build Docker image(s)"
  echo "  --docker-run            Build and run a Docker image"
  echo "  --docker-tag <tag>      Specify the Docker image tag (default: local)"
  echo "  --image <name>          Image to build/run: ubuntu, arch, or all (default: all for build, ubuntu for run)"
  echo "  -h, --help              Show this help message"
  printf "\n\n"
}

function is_supported_image {
  local image_name="$1"
  local supported_image
  for supported_image in "${SUPPORTED_IMAGES[@]}"; do
    if [[ "$supported_image" == "$image_name" ]]; then
      return 0
    fi
  done
  return 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --docker-build) docker_build_flag="true" ;;
    --docker-run) docker_run_flag="true" ;;
    --docker-tag) docker_image_tag="$2"; shift ;;
    --image)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --image"
        print_usage
        exit 1
      fi
      if [[ "$2" == "all" ]]; then
        selected_images=("${SUPPORTED_IMAGES[@]}")
      elif is_supported_image "$2"; then
        selected_images+=("$2")
      else
        echo "Unknown image: $2"
        print_usage
        exit 1
      fi
      shift
      ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
  esac
  shift
done

if [[ "${#selected_images[@]}" -eq 0 ]]; then
  if [[ "$docker_run_flag" == "true" ]]; then
    selected_images=("ubuntu")
  else
    selected_images=("${SUPPORTED_IMAGES[@]}")
  fi
fi

function print_stage {
  local stage_name="$1"
  echo ""
  echo "=========================================="
  echo "Starting stage: $stage_name"
  echo "=========================================="
  echo ""
}

function docker_image_name {
  local image_name="$1"
  echo "dotfiles-dev-${image_name}:${docker_image_tag}"
}

function dockerfile_path {
  local image_name="$1"
  echo "$SCRIPT_ROOT/containers/${image_name}/Dockerfile"
}

function build_docker_image {
  local image_name="$1"
  print_stage "Building Docker Image (${image_name})"

  docker build \
    -f "$(dockerfile_path "$image_name")" \
    -t "$(docker_image_name "$image_name")" \
    "$SCRIPT_ROOT"

  if [[ "$?" -ne 0 ]]; then
    printf "\nFailed to build Docker image\n"
    exit 1
  else
    printf "\nSuccessfully built Docker image %s\n" "$(docker_image_name "$image_name")"
  fi
}

function run_docker_image {
  local image_name="$1"
  print_stage "Running Docker Image (${image_name})"

  local docker_tty_args=()
  if [[ -t 0 && -t 1 ]]; then
    docker_tty_args=("-it")
  fi

  docker run --rm "${docker_tty_args[@]}" \
    -v "$CONTAINER_SOURCE_ROOT" \
    -w "$CONTAINER_WORKDIR" \
    "$(docker_image_name "$image_name")"

  if [[ "$?" -ne 0 ]]; then
    printf "\nDocker run failed\n"
    exit 1
  fi
}

if [[ "$docker_build_flag" != "true" && "$docker_run_flag" != "true" ]]; then
  print_usage
  exit 1
fi

if [[ "$docker_run_flag" == "true" && "${#selected_images[@]}" -ne 1 ]]; then
  echo "--docker-run requires exactly one image (use --image ubuntu or --image arch)"
  exit 1
fi

if [[ "$docker_build_flag" == "true" || "$docker_run_flag" == "true" ]]; then
  for image_name in "${selected_images[@]}"; do
    build_docker_image "$image_name"
  done
fi

if [[ "$docker_run_flag" == "true" ]]; then
  run_docker_image "${selected_images[0]}"
fi
