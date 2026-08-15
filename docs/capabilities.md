# ramalama-stack capabilities

`ramalama-stack` ships a [Llama Stack](https://github.com/meta-llama/llama-stack) distribution defined in
[`ramalama-run.yaml`](../src/ramalama_stack/ramalama-run.yaml). That file wires up more than just the
`ramalama` inference provider used in the [README](../README.md) quickstart - it enables most of the
Llama Stack APIs, backed by a mix of the `ramalama` inference provider and Llama Stack's built-in
providers. This page walks through what is enabled and how to use it.

All providers below are documented in more detail in the
[Llama Stack providers reference](https://llama-stack.readthedocs.io/en/latest/providers/index.html).

## Inference

- `ramalama` (`remote::ramalama`) - routes chat completions to the RamaLama server configured via
  `RAMALAMA_URL` (defaults to `http://localhost:8080`). This is the provider used for `INFERENCE_MODEL`
  in the README quickstart.
- `sentence-transformers` (`inline::sentence-transformers`) - runs the `all-MiniLM-L6-v2` embedding model
  locally, used by the vector DB / RAG examples below.

## Vector IO and RAG

The `milvus` (`inline::milvus`) vector-io provider gives you a local vector database backed by SQLite, so
you can build retrieval-augmented generation (RAG) on top of RamaLama without standing up a separate
vector store. A minimal example:

```python
from llama_stack_client import LlamaStackClient, RAGDocument

client = LlamaStackClient(base_url="http://localhost:8321", api_key="none")

client.vector_dbs.register(
    vector_db_id="my_docs",
    embedding_model="all-MiniLM-L6-v2",
    embedding_dimension=384,
    provider_id="milvus",
)

client.tool_runtime.rag_tool.insert(
    documents=[
        RAGDocument(document_id="doc_0", content="RamaLama Stack ...", mime_type="text/plain"),
    ],
    vector_db_id="my_docs",
    chunk_size_in_tokens=128,
)

result = client.tool_runtime.rag_tool.query(content="What is RamaLama Stack?", vector_db_ids=["my_docs"])
```

See [`tests/test-rag.py`](../tests/test-rag.py) for a complete, runnable example including feeding the
retrieved context back into `inference.chat_completion`.

## Tool runtime

Several remote and inline tool-runtime providers are registered, exposed as `tool_groups` your agents can
call:

- `builtin::rag` (`rag-runtime`) - the RAG insert/query APIs used above.
- `builtin::websearch` (`tavily-search`) - web search via [Tavily](https://tavily.com/); needs
  `TAVILY_SEARCH_API_KEY`. `brave-search` (`remote::brave-search`) is also registered as a provider if you
  prefer [Brave Search](https://brave.com/search/api/) and set `BRAVE_SEARCH_API_KEY`, though it is not
  wired up as a `tool_group` by default.
- `builtin::wolfram_alpha` (`wolfram-alpha`) - computational queries via
  [Wolfram Alpha](https://products.wolframalpha.com/api); needs `WOLFRAM_ALPHA_API_KEY`.
- `model-context-protocol` (`remote::model-context-protocol`) - lets agents call tools exposed by an
  [MCP](https://modelcontextprotocol.io/) server.

Any provider that needs an API key is safe to leave unset - it will simply be unusable until you export
the corresponding environment variable.

## Agents

The `meta-reference` (`inline::meta-reference`) agents provider persists agent and response state to
SQLite under `${SQLITE_STORE_DIR:=~/.llama/distributions/ramalama}`. Combine it with the tool groups above
to build an agent that can search the web, query Wolfram Alpha, or retrieve from your RAG vector DB in
addition to plain chat completion.

## Safety

The `llama-guard` (`inline::llama-guard`) provider runs [Llama Guard](https://ai.meta.com/llama/) as a
shield you can attach to agent turns to moderate inputs and outputs. It ships with an empty
`excluded_categories` list, so all default hazard categories are enforced; adjust the list in
`ramalama-run.yaml` to relax specific categories.

## Scoring and eval

- `basic` (`inline::basic`) and `llm-as-judge` (`inline::llm-as-judge`) scoring providers let you grade
  model outputs programmatically or by asking another model to judge them.
- `braintrust` (`inline::braintrust`) adds [Braintrust](https://www.braintrust.dev/) scoring functions if
  you set `OPENAI_API_KEY` (Braintrust proxies through the OpenAI API format).
- `meta-reference` (`inline::meta-reference`) eval provider runs benchmarks/evaluations over datasets
  registered through the `datasetio` API, using the scoring functions above.

## Post-training

The `huggingface` (`inline::huggingface`) post-training provider supports fine-tuning workflows on CPU,
producing checkpoints in the Hugging Face format. This is the heaviest-weight provider in the distribution
and is best suited to experimentation rather than production fine-tuning.

## Dataset IO

Two `datasetio` providers are available for feeding datasets into eval and scoring: `huggingface`
(`remote::huggingface`), for pulling datasets from the Hugging Face Hub, and `localfs`
(`inline::localfs`), for datasets stored on local disk.

## Telemetry

The `meta-reference` (`inline::meta-reference`) telemetry provider emits traces and metrics to the sinks
listed in `TELEMETRY_SINKS` (defaults to `console,sqlite`), so you can inspect request traces without
standing up an external collector. Set `OTEL_SERVICE_NAME` to change the reported service name.

## Where this is configured

All of the above is defined in [`ramalama-run.yaml`](../src/ramalama_stack/ramalama-run.yaml), which is
installed to `~/.llama/distributions/ramalama/ramalama-run.yaml` per the README's setup instructions. Any
provider you don't need can be removed from that file; any API key left unset simply leaves the
corresponding provider unusable until configured.
