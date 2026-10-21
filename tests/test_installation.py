"""Tests for the installed package.

These check that the environment created by ``uv sync`` exposes the
project under its own name, which is what the notebooks in ``analyses``
and the remaining tests in this directory rely on.
"""

import importlib

import au_detection_mh

# Modules of the package that the analyses import from. Add an entry
# whenever a module is added to au_detection_mh/.
EXPECTED_MODULES = ("analyses", "preprocessing", "utils")


def test_package_is_importable():
    """The project is installed and importable under its own name."""
    assert au_detection_mh.__name__ == "au_detection_mh"


def test_expected_modules_are_importable():
    """Every module the analyses import can be imported on its own."""
    for name in EXPECTED_MODULES:
        module = importlib.import_module(f"au_detection_mh.{name}")
        assert module.__name__ == f"au_detection_mh.{name}"
