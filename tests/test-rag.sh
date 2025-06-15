#!/bin/bash

function test_rag_functionality {
  echo "===> test_rag_functionality: start"

  if uv run python tests/test-rag.py; then
    echo "===> test_rag_functionality: pass"
    return 0
  else
    echo "===> test_rag_functionality: fail"
    echo "RAG test script output above shows the failure details"
    return 1
  fi
}

main() {
  echo "===> starting 'test-rag'..."

  # Check if services are already running (from previous tests)
  if curl -s http://localhost:8321/v1/health >/dev/null 2>&1 && curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo "Using existing RamaLama and Llama Stack servers"
  else
    echo "Starting fresh servers for RAG test"
    start_and_wait_for_ramalama_server
    start_and_wait_for_llama_stack_server
  fi

  if test_rag_functionality; then
    echo "===> 'test-rag' completed successfully!"
  else
    echo "===> 'test-rag' failed!"
    exit 1
  fi
}

TEST_UTILS=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$TEST_UTILS/utils.sh"
main "$@"
exit 0
