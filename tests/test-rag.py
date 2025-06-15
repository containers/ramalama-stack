import os
import uuid
from llama_stack_client import LlamaStackClient, RAGDocument


def setup_client():
    """Initialize Llama Stack client with configuration"""
    base_url = "http://localhost:8321"

    client = LlamaStackClient(base_url=base_url, api_key="none", timeout=10.0)

    print(f"Connected to Llama Stack server at {base_url}")
    return client


def setup_inference_params():
    """Configure inference parameters"""
    model_id = os.getenv(
        "INFERENCE_MODEL",
        "bartowski/Meta-Llama-3-8B-Instruct-GGUF/Meta-Llama-3-8B-Instruct-Q5_K_M.gguf",
    )

    temperature = float(os.getenv("TEMPERATURE", 0.0))
    if temperature > 0.0:
        top_p = float(os.getenv("TOP_P", 0.95))
        strategy = {"type": "top_p", "temperature": temperature, "top_p": top_p}
    else:
        strategy = {"type": "greedy"}

    max_tokens = int(os.getenv("MAX_TOKENS", 4096))

    sampling_params = {
        "strategy": strategy,
        "max_tokens": max_tokens,
    }

    stream_env = os.getenv("STREAM", "False")
    stream = stream_env == "True"

    print("Inference Parameters:")
    print(f"\tModel: {model_id}")
    print(f"\tSampling Parameters: {sampling_params}")
    print(f"\tStream: {stream}")

    return model_id, sampling_params, stream


def setup_vector_db(client):
    """Setup vector database for RAG"""
    vector_db_id = f"test_vector_db_{uuid.uuid4().hex[:8]}"

    # Find embedding model from available models
    models = client.models.list()
    embedding_model = None
    for model in models:
        if hasattr(model, "model_type") and model.model_type == "embedding":
            embedding_model = model.identifier
            break

    if not embedding_model:
        raise Exception("No embedding model found")

    print(f"Using embedding model: {embedding_model}")

    # Register vector database
    client.vector_dbs.register(
        vector_db_id=vector_db_id,
        embedding_model=embedding_model,
        embedding_dimension=int(os.getenv("VDB_EMBEDDING_DIMENSION", 384)),
        provider_id=os.getenv("VDB_PROVIDER", "milvus"),
    )

    # Ingest simple test documents instead of external URLs
    test_content = [
        "RamaLama Stack is an external provider for Llama Stack that allows for the use of RamaLama for inference.",
        "Podman is a container management tool that provides a Docker-compatible command line interface without requiring a daemon.",
        "Podman can run containers rootlessly and provides robust security isolation.",
    ]

    documents = [
        RAGDocument(
            document_id=f"test_doc_{i}",
            content=content,
            mime_type="text/plain",
            metadata={"source": f"test_document_{i}"},
        )
        for i, content in enumerate(test_content)
    ]

    print(f"Ingesting {len(documents)} test documents into vector database...")
    client.tool_runtime.rag_tool.insert(
        documents=documents,
        vector_db_id=vector_db_id,
        chunk_size_in_tokens=int(os.getenv("VECTOR_DB_CHUNK_SIZE", 128)),
    )

    print(f"Vector database '{vector_db_id}' setup complete")
    return vector_db_id


def run_rag_query(client, model_id, sampling_params, stream, vector_db_id, query):
    """Execute RAG query and return response"""
    print(f"\nUser> {query}")

    rag_response = client.tool_runtime.rag_tool.query(
        content=query, vector_db_ids=[vector_db_id]
    )

    messages = [{"role": "system", "content": "You are a helpful assistant."}]

    prompt_context = rag_response.content
    extended_prompt = f"Please answer the given query using the context below.\n\nCONTEXT:\n{prompt_context}\n\nQUERY:\n{query}"
    messages.append({"role": "user", "content": extended_prompt})

    response = client.inference.chat_completion(
        messages=messages,
        model_id=model_id,
        sampling_params=sampling_params,
        stream=stream,
    )

    print("inference> ", end="")
    if stream:
        for chunk in response:
            if hasattr(chunk, "event") and hasattr(chunk.event, "delta"):
                if hasattr(chunk.event.delta, "text"):
                    print(chunk.event.delta.text, end="")
        print()
    else:
        print(response.completion_message.content)


def main():
    """Main function to run RAG test"""
    print("=== Llama Stack RAG Test ===")

    try:
        client = setup_client()
        model_id, sampling_params, stream = setup_inference_params()

        vector_db_id = setup_vector_db(client)

        queries = [
            "What is RamaLama Stack?",
            "What is Podman?",
            "Can Podman run in rootless mode?",
        ]

        print("\n=== Running RAG Queries ===")
        for query in queries:
            run_rag_query(
                client, model_id, sampling_params, stream, vector_db_id, query
            )
            print()

        print("=== RAG Test Complete ===")

    except Exception as e:
        print(f"Error: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
