import multiprocessing
import os
import shutil
import sys
from multiprocessing.pool import Pool

HIDDEN_IMPORTS = ["packaging.specifiers", "packaging.requirements",
                  "numpy.core._methods", "numpy.core._dtype_ctypes"]
DATA = [("src/urh/dev/native/lib/shared", "."), ("src/urh/plugins", "urh/plugins"), ]
EXCLUDE = ["matplotlib"]


def run_pyinstaller(cmd_list: list, env: list=None):
    cmd = " ".join(cmd_list)
    print(cmd)
    sys.stdout.flush()
    env = [] if env is None else env
    if env:
        os.system(" ".join(env) + " " + cmd)
    else:
        os.system(cmd)


if __name__ == '__main__':
    multiprocessing.freeze_support()
    cmd = ["pyinstaller"]
    if sys.platform == "darwin":
        cmd.append("--onefile")
        cmd.append("--clean")

    for hidden_import in HIDDEN_IMPORTS:
        cmd.append("--hidden-import={}".format(hidden_import))

    for src, dst in DATA:
        cmd.append("--add-data")
        cmd.append('"{}{}{}"'.format(src, os.pathsep, dst))

    for exclude in EXCLUDE:
        cmd.append("--exclude-module={}".format(exclude))

    urh_path = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))

    if sys.platform == "darwin":
        cmd.append('--icon="{}"'.format(os.path.join(urh_path, "data/icons/appicon.icns")))
    else:
        cmd.append('--icon="{}"'.format(os.path.join(urh_path, "data/icons/appicon.ico")))

    cmd.extend(["--distpath", "./pyinstaller"])

    urh_cmd = cmd + ["--name=urh", "--windowed", os.path.join(urh_path, "src/urh/main.py")]
    urh_debug_cmd = cmd + ["--name=urh_debug", os.path.join(urh_path, "src/urh/main.py")]
    cli_cmd = cmd + [os.path.join(urh_path, "src/urh/cli/urh_cli.py")]

    os.makedirs("./pyinstaller")
    if sys.platform == "darwin":
        run_pyinstaller(urh_cmd, env=["DYLD_LIBRARY_PATH=src/urh/dev/native/lib/shared"])
    else:
        with Pool(3) as p:
            p.map(run_pyinstaller, [urh_cmd, cli_cmd, urh_debug_cmd])
        shutil.copy("./pyinstaller/urh_cli/urh_cli.exe", "./pyinstaller/urh/urh_cli.exe")
        shutil.copy("./pyinstaller/urh_debug/urh_debug.exe", "./pyinstaller/urh/urh_debug.exe")
