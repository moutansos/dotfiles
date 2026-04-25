#!/bin/bash

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
project_name="dotfiles-dev-test"

namespace="default"
image_repository="ghcr.io/moutansos/dotfiles-dev"
image_tag="latest"
storage_class_name="nfs-csi"
pvc_size="20Gi"
wait_timeout="900s"

function print_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --project-name <name>   Base name for the StatefulSet and PVC (default: dotfiles-dev-test)"
  echo "  --namespace <name>      Kubernetes namespace to use (default: default)"
  echo "  --image-tag <tag>       Container image tag to run (default: latest)"
  echo "  --storage-size <size>   PVC size to request (default: 20Gi)"
  echo "  --wait-timeout <time>   Wait timeout for PVC/pod readiness (default: 900s)"
  echo "  -h, --help              Show this help message"
  printf "\n\n"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --project-name) project_name="$2"; shift ;;
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
  name: ${project_name}-pvc
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

  kubectl wait --namespace "$namespace" --for=jsonpath='{.status.phase}'=Bound pvc/"${project_name}-pvc" --timeout="$wait_timeout"

  if [[ "$?" -ne 0 ]]; then
    printf "\nPersistentVolumeClaim did not become bound\n"
    kubectl describe pvc "${project_name}-pvc" -n "$namespace"
    exit 1
  fi
}

function apply_statefulset {
  print_stage "Applying StatefulSet"

  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${project_name}
  namespace: ${namespace}
spec:
  clusterIP: None
  selector:
    app: ${project_name}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ${project_name}
  namespace: ${namespace}
spec:
  replicas: 1
  serviceName: ${project_name}
  selector:
    matchLabels:
      app: ${project_name}
  template:
    metadata:
      labels:
        app: ${project_name}
    spec:
      containers:
        - name: ${project_name}
          image: ${image_repository}:${image_tag}
          imagePullPolicy: Always
          args: ["/bin/zsh", "-lc", "sleep infinity"]
          workingDir: /home/ben
          volumeMounts:
            - name: home
              mountPath: /home/ben
      volumes:
        - name: home
          persistentVolumeClaim:
            claimName: ${project_name}-pvc
EOF

  if [[ "$?" -ne 0 ]]; then
    printf "\nFailed to apply StatefulSet\n"
    exit 1
  fi
}

function wait_for_statefulset {
  print_stage "Waiting For StatefulSet"

  kubectl rollout status --namespace "$namespace" statefulset/"$project_name" --timeout="$wait_timeout"

  if [[ "$?" -ne 0 ]]; then
    printf "\nStatefulSet did not become ready\n"
    kubectl get statefulset "$project_name" -n "$namespace"
    kubectl get pod "${project_name}-0" -n "$namespace" -o wide
    kubectl describe pod "${project_name}-0" -n "$namespace"
    exit 1
  fi
}

function attach_shell {
  print_stage "Attaching To Container"

  if [[ -t 0 && -t 1 ]]; then
    kubectl exec -n "$namespace" -it "${project_name}-0" -- /bin/zsh
  else
    kubectl exec -n "$namespace" "${project_name}-0" -- /bin/zsh -lc 'pwd && ls -la /home/ben && ls -la /home/ben/source'
  fi
}

ensure_dependencies
apply_resources
wait_for_pvc
apply_statefulset
wait_for_statefulset
attach_shell
