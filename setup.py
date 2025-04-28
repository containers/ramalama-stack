from setuptools import setup
from setuptools.command.install import install
import os
import shutil


class CustomInstallCommand(install):
    def run(self):
        # Run the standard install
        super().run()

        # Write 'providers.d' to '~/.llama/providers.d'
        # This allows users to see the remote providers
        providers_dir = os.path.join(self.install_lib, "ramalama_stack", "providers.d")
        target_dir_1 = os.path.expanduser("~/.llama/providers.d")
        try:
            os.makedirs(target_dir_1, exist_ok=True)
            shutil.copytree(providers_dir, target_dir_1, dirs_exist_ok=True)
            print(f"Copied {providers_dir} to {target_dir_1}")
        except Exception as error:
            print(f"Failed to copy {providers_dir} to {target_dir_1}. Error: {error}")
            raise

        # Write `ramalama-run.yaml` to '~/.llama/distributions/ramalama'
        # This allows users to run the stack
        run_yaml = os.path.join(self.install_lib, "ramalama_stack", "ramalama-run.yaml")
        target_dir_2 = os.path.expanduser("~/.llama/distributions/ramalama")
        try:
            os.makedirs(target_dir_2, exist_ok=True)
            shutil.copy(run_yaml, target_dir_2)
            print(f"Copied {run_yaml} to {target_dir_2}")
        except Exception as error:
            print(f"Failed to copy {providers_dir} to {target_dir_1}. Error: {error}")
            raise


setup(cmdclass={"install": CustomInstallCommand})
