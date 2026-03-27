#!/bin/bash

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="dotfiles-dev-test"

namespace="default"
image_repository="ghcr.io/moutansos/dotfiles-dev"
image_tag="latest"
storage_class_name="nfs-csi"
pvc_size="20Gi"
wait_timeout="900s"

function print_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --namespace <name>      Kubernetes namespace to use (default: default)"
  echo "  --image-tag <tag>       Container image tag to run (default: latest)"
  echo "  --storage-size <size>   PVC size to request (default: 20Gi)"
  echo "  --wait-timeout <time>   Wait timeout for PVC/pod readiness (default: 900s)"
  echo "  -h, --help              Show this help message"
  printf "\n\n"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --namespace) namespace="$2"; shift ;;
    --image-tag) image_tag="$2"; shift ;;
    --storage-size) pvc_size="$2"; shift ;;
    --wait-timeout) wait_timeout="$2"; shift ;;
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

function ensure_dependencies {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is required but was not found on PATH"
    exit 1
  fi
}

function apply_resources {
  print_stage "Applying Kubernetes Resources"

  kubectl get namespace "$namespace" >/dev/null 2>&1 || kubectl create namespace "$namespace"

  kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PROJECT_NAME}-pvc
  namespace: ${namespace}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ${storage_class_name}
  resources:
    requests:
      storage: ${pvc_size}
EOF

  if [[ "$?" -ne 0 ]]; then
    printf "\nFailed to apply Kubernetes resources\n"
    exit 1
  fi
}

function wait_for_pvc {
  print_stage "Waiting For Persistent Volume Claim"

  kubectl wait --namespace "$namespace" --for=jsonpath='{.status.phase}'=Bound pvc/"${PROJECT_NAME}-pvc" --timeout="$wait_timeout"

  if [[ "$?" -ne 0 ]]; then
    printf "\nPersistentVolumeClaim did not become bound\n"
    kubectl describe pvc "${PROJECT_NAME}-pvc" -n "$namespace"
    exit 1
  fi
}

function apply_pod {
  print_stage "Applying Pod"

  kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${PROJECT_NAME}
  namespace: ${namespace}
spec:
  restartPolicy: Never
  containers:
    - name: workspace
      image: ${image_repository}:${image_tag}
      imagePullPolicy: Always
      args: ["/bin/zsh", "-lc", "sleep infinity"]
      workingDir: /home/ben/source
      volumeMounts:
        - name: source
          mountPath: /home/ben/source
  volumes:
    - name: source
      persistentVolumeClaim:
        claimName: ${PROJECT_NAME}-pvc
EOF

  if [[ "$?" -ne 0 ]]; then
    printf "\nFailed to apply pod\n"
    exit 1
  fi
}

function wait_for_pod {
  print_stage "Waiting For Pod"

  kubectl wait --namespace "$namespace" --for=condition=Ready pod/"$PROJECT_NAME" --timeout="$wait_timeout"

  if [[ "$?" -ne 0 ]]; then
    printf "\nPod did not become ready\n"
    kubectl get pod "$PROJECT_NAME" -n "$namespace" -o wide
    kubectl describe pod "$PROJECT_NAME" -n "$namespace"
    exit 1
  fi
}

function attach_shell {
  print_stage "Attaching To Container"

  if [[ -t 0 && -t 1 ]]; then
    kubectl exec -n "$namespace" -it "$PROJECT_NAME" -- /bin/zsh
  else
    kubectl exec -n "$namespace" "$PROJECT_NAME" -- /bin/zsh -lc 'pwd && ls -la /home/ben/source'
  fi
}

ensure_dependencies
apply_resources
wait_for_pvc
apply_pod
wait_for_pod
attach_shell
