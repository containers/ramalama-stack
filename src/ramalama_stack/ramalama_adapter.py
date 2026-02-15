from .config import RamalamaImplConfig

from llama_stack.providers.utils.inference.openai_mixin import OpenAIMixin


class RamalamaInferenceAdapter(OpenAIMixin):
    config: RamalamaImplConfig

    def get_api_key(self) -> str | None:
        if self.config.auth_credential is None:
            return "NO KEY REQUIRED"
        return self.config.auth_credential.get_secret_value()

    def get_base_url(self) -> str:
        return str(self.config.base_url)
