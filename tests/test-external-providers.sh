#!/bin/bash

function start_and_wait_for_ramalama_server {
  # Start ramalama serve in background with logging to 'ramalama.log'
  nohup uv run ramalama serve "$INFERENCE_MODEL" > ramalama.log 2>&1 &
  RAMALAMA_PID=$!
  echo "Started RamaLama with PID: $RAMALAMA_PID"

  # Wait for ramalama to be ready by doing a health check
  echo "Waiting for RamaLama server..."
  for i in {1..60}; do
    echo "Attempt $i to connect to RamaLama..."
    resp=$(curl -s http://localhost:8080/health)
    if [ "$resp" == '{"status":"ok"}' ]; then
      echo "RamaLama server is up and responding!"
      break
    fi
    if [ "$i" -eq 60 ]; then
      echo "RamaLama server failed to start or respond"
      echo "RamaLama logs:"
      cat ramalama.log
      exit 1
    fi
    sleep 1
  done
}

function start_and_wait_for_llama_stack_server {
  # Start llama stack run with logging to 'lls.log'
  LLAMA_STACK_LOG_FILE=lls.log nohup uv run llama stack run run.yaml --image-type venv &
  LLS_PID=$!
  echo "Started Llama Stack with PID: $LLS_PID"

  # Wait for llama stack to be ready by doing a health check, then test for the ramalama provider
  echo "Waiting for Llama Stack server..."
  for i in {1..60}; do
    echo "Attempt $i to connect to Llama Stack..."
    resp=$(curl -s http://localhost:8321/v1/health)
    if [ "$resp" == '{"status":"OK"}' ]; then
      echo "Llama Stack server is up!"
      if grep -q -e "remote::ramalama from .*providers.d/remote/inference/ramalama.yaml" lls.log; then
        echo "Llama Stack server is using RamaLama provider"
        return
      else
        echo "Llama Stack server is not using RamaLama provider"
        echo "Server logs:"
        cat lls.log
        exit 1
      fi
    fi
    sleep 1
  done
  echo "Llama Stack server failed to start"
  echo "Server logs:"
  cat lls.log
  exit 1
}

function test_ramalama_chat_completion {
  echo "===> test_ramalama_chat_completion: start"
  # shellcheck disable=SC2016
  resp=$(curl -s -X POST http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"messages": [{"role": "user", "content": "Hello"}], "model": "$INFERENCE_MODEL"}')
  if echo "$resp" | grep -q "choices"; then
    echo "===> test_ramalama_chat_completion: pass"
    return
  else
    echo "===> test_ramalama_chat_completion: fail"
    exit 1
  fi
}

function test_llama_stack_chat_completion {
  echo "===> test_llama_stack_chat_completion: start"
  nohup uv run llama-stack-client configure --endpoint http://localhost:8321 --api-key none
  if nohup uv run llama-stack-client inference chat-completion --message "tell me a joke" | grep -q "completion_message"; then
    echo "===> test_llama_stack_chat_completion: pass"
    return
  else
    echo "===> test_llama_stack_chat_completion: fail"
    exit 1
  fi
}

main() {
  echo "===> starting 'test-external-providers'..."
  start_and_wait_for_ramalama_server
  test_ramalama_chat_completion
  start_and_wait_for_llama_stack_server
  test_llama_stack_chat_completion
  echo "===> 'test-external-providers' completed successfully!"
}

main "$@"
exit 0
