#!/bin/bash

function start_and_wait_for_streamlit_ui_linux {
  echo "Starting Streamlit UI for Linux..."

  podman run -d --rm --network=host --name=streamlit-ui quay.io/redhat-et/streamlit_client:0.1.0

  echo "Waiting for Streamlit UI to be ready..."
  for i in {1..30}; do
    echo "Attempt $i to connect to Streamlit UI..."
    if curl -s http://localhost:8501 >/dev/null 2>&1; then
      echo "Streamlit UI is up and responding on port 8501!"
      return 0
    fi
    if [ "$i" -eq 30 ]; then
      echo "Streamlit UI failed to start or respond"
      echo "Container logs:"
      podman logs streamlit-ui
      return 1
    fi
    sleep 2
  done
}

function test_streamlit_ui_linux {
  echo "===> test_streamlit_ui_linux: start"

  if start_and_wait_for_streamlit_ui_linux; then
    # Test that the UI is accessible and returns HTML content
    resp=$(curl -sS http://localhost:8501)
    if echo "$resp" | grep -q -i "streamlit\|html"; then
      echo "===> test_streamlit_ui_linux: pass"
      return 0
    else
      echo "===> test_streamlit_ui_linux: fail - UI not serving expected content"
      echo "Response: $resp"
      return 1
    fi
  else
    echo "===> test_streamlit_ui_linux: fail - UI failed to start"
    return 1
  fi
}

function cleanup_streamlit_ui {
  echo "Cleaning up Streamlit UI container..."
  podman rm -f streamlit-ui >/dev/null 2>&1 || true
}

main() {
  echo "===> starting 'test-ui-linux'..."

  # Only run on Linux
  # Need a fix to published ports in ramalama to run on MacOS
  if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This test is only for Linux systems. Current OS: $OSTYPE"
    echo "===> 'test-ui-linux' skipped!"
    exit 0
  fi

  trap cleanup_streamlit_ui EXIT

  start_and_wait_for_ramalama_server
  start_and_wait_for_llama_stack_server

  test_streamlit_ui_linux

  cleanup_streamlit_ui

  echo "===> 'test-ui-linux' completed successfully!"
}

TEST_UTILS=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$TEST_UTILS/utils.sh"
main "$@"
exit 0
