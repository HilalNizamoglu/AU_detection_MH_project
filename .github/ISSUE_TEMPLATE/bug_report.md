---
name: Bug report
about: Report something that does not work as described
title: ''
labels: ''
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To reproduce**
The command or notebook cell that triggers it, and the smallest input it
happens with:

```bash
```

**Expected behaviour**
A clear and concise description of what you expected to happen.

**Error output**
The full traceback or log, rather than the last line alone.

```
```

**Environment**
 - OS: [e.g. Ubuntu 22.04, macOS 15]
 - Python: output of `uv run python --version`
 - uv: output of `uv --version`
 - au_detection_mh: output of `uv pip show au_detection_mh | head -2`
 - Installed from: [a clone and `uv sync`, or a container image]

**If you are running a container**
 - Engine and version: [e.g. podman 4.9.3, docker 27.1.1, apptainer 1.3.4]
 - Image and tag: [e.g. ghcr.io/vccn-lab/au_detection_mh:1.2.3, or a local build]
 - Does the same command work outside the container? [yes / no / not tried]

**Additional context**
Anything else that seems relevant, such as a dataset that triggers it or
a recent change in your environment.
