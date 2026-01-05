#!/bin/bash
# Enhanced log viewer for llama-swappo-halo and Flux

set -e

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -a, --app       Show llama-swappo-halo application logs (default)"
  echo "  -f, --flux      Show Flux controller logs"
  echo "  -n, --namespace  Show logs for specific namespace"
  echo "  -p, --pod       Show logs for specific pod"
  echo "  -t, --tail      Number of lines to show (default: 100)"
  echo "  -h, --help      Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                    # Show app logs"
  echo "  $0 --flux             # Show Flux logs"
  echo "  $0 --pod my-pod       # Show logs for specific pod"
  echo "  $0 --tail 50          # Show last 50 lines"
  exit 0
}

# Default values
LOG_TYPE="app"
NAMESPACE=""
POD_NAME=""
TAIL_LINES=100
FOLLOW=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--app)
      LOG_TYPE="app"
      shift
      ;;
    -f|--flux)
      LOG_TYPE="flux"
      shift
      ;;
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -p|--pod)
      POD_NAME="$2"
      shift 2
      ;;
    -t|--tail)
      TAIL_LINES="$2"
      shift 2
      ;;
    --follow)
      FOLLOW=true
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

# Function to show app logs
show_app_logs() {
  echo "=== llama-swappo-halo Logs ==="
  echo ""

  # Find the pod
  if [ -z "$POD_NAME" ]; then
    POD=$(kubectl get pods -l app=llama-swappo-halo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$POD" ]; then
      echo "Error: No llama-swappo-halo pod found"
      exit 1
    fi
    POD_NAME="$POD"
  fi

  echo "Pod: $POD_NAME"
  echo "Lines: $TAIL_LINES"
  echo ""

  if [ "$FOLLOW" = true ]; then
    kubectl logs -f "$POD_NAME" --tail=$TAIL_LINES
  else
    kubectl logs "$POD_NAME" --tail=$TAIL_LINES
  fi
}

# Function to show Flux logs
show_flux_logs() {
  echo "=== Flux Controller Logs ==="
  echo ""

  local flux_pods=$(kubectl get pods -n flux-system -o jsonpath='{.items[*].metadata.name}')

  if [ -z "$flux_pods" ]; then
    echo "Error: No Flux pods found"
    exit 1
  fi

  for pod in $flux_pods; do
    echo ""
    echo "--- $pod ---"
    if [ "$FOLLOW" = true ]; then
      kubectl logs -n flux-system "$pod" --tail=$TAIL_LINES -f &
    else
      kubectl logs -n flux-system "$pod" --tail=$TAIL_LINES
    fi
  done

  if [ "$FOLLOW" = true ]; then
    wait
  fi
}

# Execute based on log type
case $LOG_TYPE in
  app)
    show_app_logs
    ;;
  flux)
    show_flux_logs
    ;;
esac
