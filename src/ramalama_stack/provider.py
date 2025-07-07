from llama_stack.providers.datatypes import (
    ProviderSpec,
    Api,
    AdapterSpec,
    remote_provider_spec,
)


def get_provider_spec() -> ProviderSpec:
    return remote_provider_spec(
        api=Api.inference,
        adapter=AdapterSpec(
            adapter_type="ramalama",
            pip_packages=["ramalama>=0.8.5", "pymilvus"],
            config_class="ramalama_stack.config.RamalamaImplConfig",
            module="ramalama_stack",
        ),
    )
