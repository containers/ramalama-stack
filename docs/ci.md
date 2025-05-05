# ramalama-stack CI

| Job | Description | Status |
| --- | ----------- | ------ |
| [Pre-commit](https://github.com/containers/ramalama-stack/blob/main/.github/workflows/pre-commit.yml) | Runs pre-commit checks | ![Pre-commit](https://github.com/containers/ramalama-stack/actions/workflows/pre-commit.yml/badge.svg?branch=main) |
| [Test External Providers](https://github.com/containers/ramalama-stack/blob/main/.github/workflows/test-external-providers.yml) | Tests the current `ramalama-stack` branch against the latest released versions of `ramalama` and `llama-stack` | ![Test External Providers](https://github.com/containers/ramalama-stack/actions/workflows/test-external-providers.yml/badge.svg?branch=main) |
| [Test LLS Integration](https://github.com/containers/ramalama-stack/blob/main/.github/workflows/test-lls-integration.yml) | Tests the latest released versions of `ramalama` and `ramalama-stack` against the current `llama-stack` main branch | ![Test LLS Integration](https://github.com/containers/ramalama-stack/actions/workflows/test-lls-integration.yml/badge.svg?branch=main) |
| [Test Container](https://github.com/containers/ramalama-stack/blob/main/.github/workflows/test-container.yml) | Tests the latest tagged container image of `ramalama/llama-stack` run via Podman | ![Test Container](https://github.com/containers/ramalama-stack/actions/workflows/test-container.yml/badge.svg?branch=main) |
| [Build and publish PyPI package](https://github.com/containers/ramalama-stack/blob/main/.github/workflows/pypi.yml) | Builds, tests, and publishes `ramalama-stack` package | ![Build and publish PyPI package](https://github.com/containers/ramalama-stack/actions/workflows/pypi.yml/badge.svg?branch=main) |
