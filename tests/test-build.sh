#!/bin/bash

function test_file_writes {
  RUN_YAML="$HOME/.llama/distributions/ramalama/ramalama-run.yaml"

  # check for RUN_YAML
  if [ -f "$RUN_YAML" ]; then
    echo "$RUN_YAML found"
  else
    echo "$RUN_YAML not found"
    echo "===> test_file_writes: fail"
    exit 1
  fi

  # return if all checks are successfully
  echo "===> test_file_writes: pass"
  return
}

main() {
  echo "===> starting 'test-build'..."
  test_file_writes
  echo "===> 'test-build' completed successfully!"
}

main "$@"
exit 0
