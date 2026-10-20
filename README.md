# AU_detection_MH_project

Code and analysis documentation accompanying an evaluation of automatic
action unit (AU) detection tools on
[MetaHuman](https://www.unrealengine.com/en-US/metahuman) facial
animations. Four MetaHuman avatars were animated in Unreal Engine 5 with
known rig activations, rendered to video, and passed through
[OpenFace](https://github.com/TadasBaltrusaitis/OpenFace), the
[AFAR toolbox](https://github.com/AffectAnalysisGroup/AFARtoolbox) and
[py-feat](https://py-feat.org/). Because the rig activation is known
frame by frame, each detector's output can be scored against a ground
truth that a human-coded corpus does not provide.

The analyses ask three things of each detector: whether it detects the
AU that was animated (binary classification performance), whether it
detects it at the right time (temporal alignment), and whether the
facial motion it responds to is in the right place (landmark
displacement).

Dependencies are managed with [uv](https://docs.astral.sh/uv/) and
containers are built with [podman](https://podman.io/) and
[Apptainer](https://apptainer.org/).

## Repository layout

| Path | Contents |
| --- | --- |
| `au_detection_mh/` | The code the analyses call, installed as a package |
| `analyzes/` | Notebooks documenting the analyses, one per step |
| `tests/` | `pytest` tests for the code in `au_detection_mh/` |
| `ds-au_detection_mh/` | The dataset and its derivatives, with the rules on what may be committed |
| `matlab/` | MATLAB sources that ran the detectors and produced the data |
| `unreal/` | Unreal Engine 5 Python scripts that built the animations |
| `generate_images.sh` | Generates and builds the container definitions |
| `.github/workflows/` | Spelling, formatting, test and container CI |

The four avatars (`Ada`, `Garry`, `Cooper`, `Pia`) are Unreal Engine
MetaHuman presets, not people, and the dataset contains no human
participant data.

## Setting up the environment

The environment is described by `pyproject.toml` and pinned by
`uv.lock`. Both are committed, so the versions an analysis ran with are
recoverable from the repository.

Install uv, if it is not present already:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Create the environment and install the package into it:

```bash
uv sync
```

`uv sync` reads `.python-version` for the interpreter, installs the
locked dependencies, adds the `dev` dependency group with the formatting
and test tooling, and installs `au_detection_mh` in editable mode. Add
`--extra notebooks` for Jupyter Lab, the kernel, and the plotting and
hypothesis-testing packages the notebooks use.

Run anything inside that environment with `uv run`:

```bash
uv run python -c "import au_detection_mh"
uv run jupyter lab
```

### Changing dependencies

```bash
uv add numpy           # add a runtime dependency
uv add --dev pytest    # add a development dependency
uv remove numpy        # drop one
uv lock --upgrade      # re-resolve within the declared bounds
```

Each of these rewrites `uv.lock`. Commit `pyproject.toml` and `uv.lock`
in the same commit, since CI installs with `--frozen` and fails when the
two disagree.

## Running the analyses

The notebooks in `analyzes/` are numbered in the order they run.
`01_classification_metrics.ipynb` writes the tables the other three
read, so run it first in a fresh checkout; the tables it writes are also
committed, so the later notebooks run without it.

```bash
uv sync --extra notebooks
uv run jupyter lab
```

The steps that produced the dataset in the first place — the Unreal
Engine animations and the three detector runs — are in `unreal/` and
`matlab/`, need MATLAB and Unreal Engine, and are documented in the
README in each of those directories.

## Data

`ds-au_detection_mh/` carries the dataset: the rig ground truth and the
three detectors' predictions under `sourcedata/`, and the landmark
displacement traces and group-level results under `derivatives/`.
Everything published comes to roughly 5 MB and is committed directly.
The rendered animation videos are not committed and are reproducible
from `unreal/UE5_SequencerScripting.py`.

Two questions decide whether a given file belongs there in version
control, and a file has to pass both: it has to be small enough for git,
and it has to be free of identifying information.
`ds-au_detection_mh/README.md` gives the thresholds, the list of things
to check for, and where the information hides outside the top-level
columns of a table.

Check before committing rather than afterwards. A push is public, and
removing a file in a later commit leaves it in the history.

## Running the checks

The workflows in `.github/workflows/` run these three commands. Run them
locally before committing:

```bash
uv run codespell
uv run flake8 au_detection_mh/ tests/ unreal/
uv run pytest
```

## Containers

`generate_images.sh` writes the container definitions with
[neurodocker](https://github.com/ReproNim/neurodocker), which it runs
through `uvx`, so generating them needs no container runtime. Inside the
images, `uv sync --frozen` installs the versions from `uv.lock`, which
has to be committed before an image can be built.

The images carry the Python analyses. They do not carry MATLAB or Unreal
Engine, so the steps in `matlab/` and `unreal/` cannot be re-run inside
them; those directories are copied in so that the record of how the data
was produced travels with the image.

Generate both definitions:

```bash
bash generate_images.sh both
```

Generate and build both images:

```bash
bash generate_images.sh both local
```

`Dockerfile` is built with `podman`, which runs rootless and needs no
daemon. `Singularity.def` is built with `apptainer build --fakeroot`,
which also needs no daemon. Both require an `/etc/subuid` and
`/etc/subgid` entry for your user.

Set `APPTAINER_TMPDIR` and `APPTAINER_CACHEDIR` to local scratch before
building the `.sif`, or apptainer will place several GB of intermediates
under `/tmp` and `$HOME`:

```bash
export APPTAINER_TMPDIR=/raid/$USER/apptainer-tmp
export APPTAINER_CACHEDIR=/raid/$USER/apptainer-cache
```

### Running the containers

The OCI image starts Jupyter Lab on port 8888:

```bash
podman run --rm -p 8888:8888 au_detection_mh:local
```

Mount the dataset to work on data that is kept outside the image. `:Z`
relabels the mount for SELinux and is harmless where SELinux is not
enforced:

```bash
podman run --rm -p 8888:8888 \
    -v /path/to/ds-au_detection_mh:/home/au_detection_mh/ds-au_detection_mh:Z \
    au_detection_mh:local
```

If podman reports that it `could not find slirp4netns`, the container is
left with no network interface beyond loopback, and `-p` publishes
nothing. Rootless podman needs `slirp4netns` or `pasta` to give a
container its own network namespace. Where neither is installed, share
the host network instead, which puts Jupyter on port 8888 of the host
directly:

```bash
podman run --rm --network=host au_detection_mh:local
```

`podman build` is unaffected, because it runs its steps in the host
network namespace already.

The Apptainer image bind-mounts `$HOME` and the current directory
already, and takes the command to run:

```bash
apptainer run au_detection_mh.sif jupyter lab --no-browser --ip=0.0.0.0
apptainer exec au_detection_mh.sif pytest
```

### Published images

The container workflow builds the image on every push and pull request,
and publishes it to the GitHub Container Registry on pushes to `main`
and on `v*` tags, authenticating with the `GITHUB_TOKEN` the workflow
already has. A tag push publishes the version number, so pull by that
tag rather than by `latest`:

```bash
podman pull ghcr.io/peerherholz/au_detection_mh:1.2.3
```

To publish to Docker Hub as well, add the repository name to `images:`
in `.github/workflows/container_build_publish.yml`, set the
`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` repository secrets, and
re-add the Docker Hub login step.

The `.sif` is not published by CI. Push one from a local build with:

```bash
REGISTRY_OWNER=peerherholz IMAGE_TAG=1.2.3 \
    bash generate_images.sh singularity local push
```

That stores it as an OCI artifact, so it is retrieved with
`apptainer pull oras://...` rather than with `podman pull`.

## License

See [LICENSE](LICENSE).
