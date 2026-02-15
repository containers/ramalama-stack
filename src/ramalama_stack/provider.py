from llama_stack.providers.datatypes import (
    ProviderSpec,
    Api,
    RemoteProviderSpec,
)


def get_provider_spec() -> ProviderSpec:
    return RemoteProviderSpec(
        api=Api.inference,
        provider_type="remote::ramalama",
        adapter_type="ramalama",
        pip_packages=[],
        config_class="ramalama_stack.config.RamalamaImplConfig",
        module="ramalama_stack",
    )
