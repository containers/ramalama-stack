from typing import Any, Dict

from pydantic import BaseModel

DEFAULT_RAMALAMA_URL = "http://localhost:8080"


class RamalamaImplConfig(BaseModel):
    url: str = DEFAULT_RAMALAMA_URL

    @classmethod
    def sample_run_config(
        cls, url: str = "${env.RAMALAMA_URL:http://localhost:8080}", **kwargs
    ) -> Dict[str, Any]:
        return {"url": url}
