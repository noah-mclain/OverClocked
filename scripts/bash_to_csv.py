import subprocess
import os
import csv


def run_script():
    path = os.path.join("collect_metrics.sh")
    try:
        result = subprocess.run(["bash", path],
                                stdout = subprocess.PIPE,
                                stdin = subprocess.PIPE,
                                capture_output = True,
                                text = True)
        if result.returncode != 0:
            raise RuntimeError("Bash script error")
        return result.stdout
    except:
        raise FileNotFoundError("File not found")