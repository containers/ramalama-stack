from setuptools import setup
from setuptools.command.develop import develop
from setuptools.command.install import install
import os
import shutil


def write_files(install_lib):
    # Write 'providers.d' to '~/.llama/providers.d'
    # This allows users to see the remote providers
    providers_dir = os.path.join(install_lib, "ramalama_stack", "providers.d")
    target_dir_1 = os.path.expanduser("~/.llama/providers.d")
    print(f"Copying {providers_dir} to {target_dir_1}")
    try:
        os.makedirs(target_dir_1, exist_ok=True)
        shutil.copytree(providers_dir, target_dir_1, dirs_exist_ok=True)
        print(f"Copied {providers_dir} to {target_dir_1}")
    except Exception as error:
        print(f"Failed to copy {providers_dir} to {target_dir_1}. Error: {error}")
        raise

    # Write `ramalama-run.yaml` to '~/.llama/distributions/ramalama'
    # This allows users to run the stack
    run_yaml = os.path.join(install_lib, "ramalama_stack", "ramalama-run.yaml")
    target_dir_2 = os.path.expanduser("~/.llama/distributions/ramalama")
    print(f"Copying {run_yaml} to {target_dir_2}")
    try:
        os.makedirs(target_dir_2, exist_ok=True)
        shutil.copy(run_yaml, target_dir_2)
        print(f"Copied {run_yaml} to {target_dir_2}")
    except Exception as error:
        print(f"Failed to copy {providers_dir} to {target_dir_2}. Error: {error}")
        raise


class PostDevelopCommand(develop):
    """Post-installation for development mode."""

    def run(self):
        # Run the standard install
        develop.run(self)

        # Write files to filesystem
        write_files(self.install_lib)


class PostInstallCommand(install):
    """Post-installation for installation mode."""

    def run(self):
        # Run the standard install
        install.run(self)

        # Write files to filesystem
        write_files(self.install_lib)


setup(cmdclass={"develop": PostDevelopCommand, "install": PostInstallCommand})
