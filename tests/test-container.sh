#!/bin/bash

main() {
  echo "===> starting 'test-container'..."
  start_and_wait_for_ramalama_server
  test_ramalama_chat_completion
  start_and_wait_for_llama_stack_container
  test_llama_stack_chat_completion
  test_llama_stack_openai_chat_completion
  echo "===> 'test-container' completed successfully!"
}

TEST_UTILS=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck disable=SC1091
source "$TEST_UTILS/utils.sh"
main "$@"
exit 0
