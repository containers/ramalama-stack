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
            pip_packages=["ramalama>=0.7.5", "faiss-cpu"],
            config_class="config.RamalamaImplConfig",
            module="ramalama_adapter",
        ),
    )
