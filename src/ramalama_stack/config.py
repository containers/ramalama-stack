from typing import Any

from pydantic import Field, HttpUrl

from llama_stack.providers.utils.inference.model_registry import RemoteInferenceProviderConfig
from llama_stack_api import json_schema_type

@json_schema_type
class RamalamaImplConfig(RemoteInferenceProviderConfig):
    base_url: HttpUrl | None = Field(
        default=HttpUrl("http://localhost:8080/v1"),
        description="The URL for the Ramalama server",
    )

    @classmethod
    def sample_run_config(cls, **kwargs) -> dict[str, Any]:
        return {
            "base_url": "http://localhost:8080/v1",
        }
