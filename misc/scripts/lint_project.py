#!/usr/bin/env python3
"""
Simple python wrapper to launch various linter
"""

from os.path import join, realpath, pardir, dirname
from os import walk, system
from fnmatch import fnmatch
import sys

PROJECT_DIR = realpath(join(dirname(realpath(__file__)), pardir, pardir))

LINT_CONFIG = {
    'shellcheck': ['*.sh', 'generic-functions'],
    'yamllint': ['*.yml', '*.yaml'],
    'pylint3': ['*.py'],
    'tflint': ['*.tf']
}

def lint_file(file, lint_config):
    """Linting file with configured linters.
    Return True if file linted without errors
    """
    lint_status = True
    for linter, file_types in lint_config.items():
        for file_type in file_types:
            if fnmatch(file, file_type):
                cmd = linter + ' ' + file
                if system(cmd) != 0:
                    print("Execute '%s': ERROR" % cmd)
                    lint_status = False
                else:
                    print("Execute '%s': OK" % cmd)
    return lint_status


def main():
    """Main function to run linters
    """
    project_error = False
    for root, _, files in walk(PROJECT_DIR):
        if not fnmatch(root, '*/.*'):
            for file in files:
                if not lint_file(join(root, file), LINT_CONFIG):
                    project_error = True

    if project_error:
        sys.exit("Lint project: ERROR")
    else:
        print("Lint project: OK")

main()
