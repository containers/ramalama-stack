#!/bin/bash

function start_and_wait_for_ramalama_server {
  # Start ramalama serve in background with logging to 'ramalama-$INFERENCE_MODEL_NO_COLON.log'
  nohup uv run ramalama serve "$INFERENCE_MODEL" > "ramalama-$INFERENCE_MODEL_NO_COLON.log" 2>&1 &
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
      cat "ramalama-$INFERENCE_MODEL_NO_COLON.log"
      exit 1
    fi
    sleep 1
  done
}

function start_and_wait_for_llama_stack_server {
  # Start llama stack run with logging to 'lls-$INFERENCE_MODEL_NO_COLON.log'
  LLAMA_STACK_LOG_FILE="lls-$INFERENCE_MODEL_NO_COLON.log" nohup uv run llama stack run ~/.llama/distributions/ramalama/ramalama-run.yaml --image-type venv &
  LLS_PID=$!
  echo "Started Llama Stack server with PID: $LLS_PID"

  # Wait for llama stack to be ready by doing a health check, then test for the ramalama provider
  echo "Waiting for Llama Stack server..."
  for i in {1..60}; do
    echo "Attempt $i to connect to Llama Stack..."
    resp=$(curl -s http://localhost:8321/v1/health)
    if [ "$resp" == '{"status":"OK"}' ]; then
      echo "Llama Stack server is up!"
      if grep -q -e "remote::ramalama from .*providers.d/remote/inference/ramalama.yaml" "lls-$INFERENCE_MODEL_NO_COLON.log"; then
        echo "Llama Stack server is using RamaLama provider"
        return
      else
        echo "Llama Stack server is not using RamaLama provider"
        echo "Server logs:"
        cat "lls-$INFERENCE_MODEL_NO_COLON.log"
        exit 1
      fi
    fi
    sleep 1
  done
  echo "Llama Stack server failed to start"
  echo "Server logs:"
  cat "lls-$INFERENCE_MODEL_NO_COLON.log"
  exit 1
}

function start_and_wait_for_llama_stack_container {
  # Start llama stack run
  podman run \
    -d \
    --net=host \
    --env INFERENCE_MODEL="$INFERENCE_MODEL" \
    --env RAMALAMA_URL=http://0.0.0.0:8080 \
    --name llama-stack \
    quay.io/ramalama/llama-stack:latest
  LLS_PID=$!
  echo "Started Llama Stack container with PID: $LLS_PID"

  # Wait for llama stack to be ready by doing a health check, then test for the ramalama provider
  echo "Waiting for Llama Stack server..."
  for i in {1..60}; do
    echo "Attempt $i to connect to Llama Stack..."
    resp=$(curl -s http://localhost:8321/v1/health)
    if [ "$resp" == '{"status":"OK"}' ]; then
      echo "Llama Stack server is up!"
      if podman logs llama-stack | grep -q -e "remote::ramalama from .*providers.d/remote/inference/ramalama.yaml"; then
        echo "Llama Stack server is using RamaLama provider"
        return
      else
        echo "Llama Stack server is not using RamaLama provider"
        echo "Container logs:"
        podman logs llama-stack
        exit 1
      fi
    fi
    sleep 1
  done
  echo "Llama Stack server failed to start"
  echo "Container logs:"
  podman logs llama-stack
  exit 1
}

function test_ramalama_models {
  echo "===> test_ramalama_models: start"
  # shellcheck disable=SC2016
  resp=$(curl -sS http://localhost:8080/v1/models)
  if echo "$resp" | grep -q "$INFERENCE_MODEL"; then
    echo "===> test_ramalama_models: pass"
    return
  else
    echo "===> test_ramalama_models: fail"
    echo "RamaLama logs:"
    cat "ramalama-$INFERENCE_MODEL_NO_COLON.log"
    exit 1
  fi
}

function test_ramalama_chat_completion {
  echo "===> test_ramalama_chat_completion: start"
  # shellcheck disable=SC2016
  resp=$(curl -sS -X POST http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}], \"model\": \"$INFERENCE_MODEL\"}")
  if echo "$resp" | grep -q "choices"; then
    echo "===> test_ramalama_chat_completion: pass"
    return
  else
    echo "===> test_ramalama_chat_completion: fail"
    echo "RamaLama logs:"
    cat "ramalama-$INFERENCE_MODEL_NO_COLON.log"
    exit 1
  fi
}

function test_llama_stack_models {
  echo "===> test_llama_stack_models: start"
  nohup uv run llama-stack-client configure --endpoint http://localhost:8321 --api-key none
  if nohup uv run llama-stack-client models list | grep -q "$INFERENCE_MODEL"; then
    echo "===> test_llama_stack_models: pass"
    return
  else
    echo "===> test_llama_stack_models: fail"
    echo "Server logs:"
    cat "lls-$INFERENCE_MODEL_NO_COLON.log" || podman logs llama-stack
    exit 1
  fi
}

function test_llama_stack_openai_models {
  echo "===> test_llama_stack_openai_models: start"
  # shellcheck disable=SC2016
  resp=$(curl -sS http://localhost:8321/v1/openai/v1/models)
  if echo "$resp" | grep -q "$INFERENCE_MODEL"; then
    echo "===> test_llama_stack_openai_models: pass"
    return
  else
    echo "===> test_llama_stack_openai_models: fail"
    echo "Server logs:"
    cat "lls-$INFERENCE_MODEL_NO_COLON.log" || podman logs llama-stack
    exit 1
  fi
}

function test_llama_stack_chat_completion {
  echo "===> test_llama_stack_chat_completion: start"
  nohup uv run llama-stack-client configure --endpoint http://localhost:8321 --api-key none
  resp=$(nohup uv run llama-stack-client inference chat-completion --message "tell me a joke")
  if echo "$resp" | grep -q "OpenAIChatCompletion"; then
    echo "===> test_llama_stack_chat_completion: pass"
    return
  else
    echo "===> test_llama_stack_chat_completion: fail"
    echo "Server logs:"
    cat "lls-$INFERENCE_MODEL_NO_COLON.log" || podman logs llama-stack
    exit 1
  fi
}

function test_llama_stack_openai_chat_completion {
  echo "===> test_llama_stack_openai_chat_completion: start"
  # shellcheck disable=SC2016
  resp=$(curl -sS -X POST http://localhost:8321/v1/openai/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}], \"model\": \"$INFERENCE_MODEL\"}")
  if echo "$resp" | grep -q "choices"; then
    echo "===> test_llama_stack_openai_chat_completion: pass"
    return
  else
    echo "===> test_llama_stack_openai_chat_completion: fail"
    echo "Server logs:"
    cat "lls-$INFERENCE_MODEL_NO_COLON.log" || podman logs llama-stack
    exit 1
  fi
}

function start_and_wait_for_llama_stack_ui {
  echo "Starting Streamlit UI..."

  podman run -d --rm --network=host --name=streamlit-ui quay.io/redhat-et/streamlit_client:0.1.0 || { echo "ERROR: Failed to start streamlit-ui container."; return 1; }

  echo "Waiting for Streamlit UI to be ready..."
  for i in {1..30}; do
    echo "Attempt $i to connect to Streamlit UI..."
    if curl -s http://localhost:8501 >/dev/null 2>&1; then
      echo "Streamlit UI is up and responding on port 8501"
      return 0
    fi
    sleep 2
  done

  echo "Streamlit UI failed to start or respond"
  echo "Container logs:"
  podman logs streamlit-ui
  return 1
}

function test_llama_stack_ui {
  echo "===> test_llama_stack_ui: start"

  trap 'echo "Stopping Streamlit UI container..."; podman stop streamlit-ui >/dev/null 2>&1' RETURN

  if ! start_and_wait_for_llama_stack_ui; then
    echo "===> test_llama_stack_ui: fail - UI failed to start"
    return 1
  fi

  resp=$(curl -sS http://localhost:8501)
  if echo "$resp" | grep -q -i "streamlit\|html"; then
    echo "===> test_llama_stack_ui: pass"
    return 0
  else
    echo "===> test_llama_stack_ui: fail - UI not serving expected content"
    echo "Response: $resp"
    return 1
  fi
}
