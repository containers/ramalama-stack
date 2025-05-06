# ramalama-stack

[![PyPI version](https://img.shields.io/pypi/v/ramalama_stack.svg)](https://pypi.org/project/ramalama-stack/)
[![PyPI - Downloads](https://img.shields.io/pypi/dm/ramalama-stack)](https://pypi.org/project/ramalama-stack/)
[![License](https://img.shields.io/pypi/l/ramalama_stack.svg)](https://github.com/containers/ramalama-stack/blob/main/LICENSE)

An external provider for [Llama Stack](https://github.com/meta-llama/llama-stack) allowing for the use of [RamaLama](https://ramalama.ai/) for inference.

## Installing

You can install `ramalama-stack` from PyPI via `pip install ramalama-stack`

This will install Llama Stack and RamaLama as well if they are not installed already.

## Usage

> [!WARNING]
> The following workaround is currently needed to run this provider - see https://github.com/containers/ramalama-stack/issues/53 for more details
> ```bash
> curl --create-dirs --output ~/.llama/providers.d/remote/inference/ramalama.yaml https://raw.githubusercontent.com/containers/ramalama-stack/refs/tags/v0.1.3/src/ramalama_stack/providers.d/remote/inference/ramalama.yaml
> curl --create-dirs --output ~/.llama/distributions/ramalama/ramalama-run.yaml https://raw.githubusercontent.com/containers/ramalama-stack/refs/tags/v0.1.3/src/ramalama_stack/ramalama-run.yaml
> ```

1. First you will need a RamaLama server running - see [the RamaLama project](https://github.com/containers/ramalama) docs for more information.

2. Ensure you set your `INFERENCE_MODEL` environment variable to the name of the model you have running via RamaLama.

3. You can then run the RamaLama external provider via `llama stack run ~/.llama/distributions/ramalama/ramalama-run.yaml`

> [!NOTE]
> You can also run the RamaLama external provider inside of a container via [Podman](https://podman.io/)
> ```bash
> podman run \
>  --net=host \
>  --env RAMALAMA_URL=http://0.0.0.0:8080 \
>  --env INFERENCE_MODEL=$INFERENCE_MODEL \
>  ramalama/llama-stack
> ```

This will start a Llama Stack server which will use port 8321 by default. You can test this works by configuring the Llama Stack Client to run against this server and
sending a test request.
- If your client is running on the same machine as the server, you can run `llama-stack-client configure --endpoint http://0.0.0.0:8321 --api-key none`
- If your client is running on a different machine, you can run `llama-stack-client configure --endpoint http://<hostname>:8321 --api-key none`
- The client should give you a message similar to `Done! You can now use the Llama Stack Client CLI with endpoint <endpoint>`
- You can then test the server by running `llama-stack-client inference chat-completion --message "tell me a joke"` which should return something like

```bash
ChatCompletionResponse(
    completion_message=CompletionMessage(
        content='A man walked into a library and asked the librarian, "Do you have any books on Pavlov\'s dogs
and Schrödinger\'s cat?" The librarian replied, "It rings a bell, but I\'m not sure if it\'s here or not."',
        role='assistant',
        stop_reason='end_of_turn',
        tool_calls=[]
    ),
    logprobs=None,
    metrics=[
        Metric(metric='prompt_tokens', value=14.0, unit=None),
        Metric(metric='completion_tokens', value=63.0, unit=None),
        Metric(metric='total_tokens', value=77.0, unit=None)
    ]
)
```
