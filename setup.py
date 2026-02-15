from setuptools import setup
from setuptools.command.install import install
import os
import shutil


class CustomInstallCommand(install):
    def run(self):
        # Run the standard install
        super().run()

        # Write `ramalama-run.yaml` to '~/.llama/distributions/ramalama'
        # This allows users to run the stack
        run_yaml = os.path.join(self.install_lib, "ramalama_stack",
                                "ramalama-run.yaml")
        target_dir = os.path.expanduser("~/.llama/distributions/ramalama")
        try:
            os.makedirs(target_dir, exist_ok=True)
            shutil.copy(run_yaml, target_dir)
            print(f"Copied {run_yaml} to {target_dir}")
        except Exception as error:
            print(f"Failed to copy {run_yaml} to {target_dir}. Error: {error}")
            raise


setup(cmdclass={"install": CustomInstallCommand})
