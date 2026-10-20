#!/bin/bash

# Script: generate_images.sh
# Purpose: Generate the Docker and Apptainer/Singularity container
#          definitions for a given project, and optionally build the
#          images from them.
# Description: neurodocker runs through uvx, so generating the
#              definitions needs no container runtime at all.  Images are
#              built with podman, which is daemonless and rootless, and
#              with apptainer, which builds the .sif with --fakeroot.
#              Inside the images, "uv sync --frozen" installs the versions
#              recorded in uv.lock, so both files have to be committed.

# Exit immediately if any command fails, if an unset variable is used, or
# if any stage of a pipeline fails
set -euo pipefail

# Name used for the package, the image, the container user and the .sif
PROJECT=au_detection_mh

# neurodocker is pinned so that regenerating the committed definitions
# produces the same output rather than drifting with whatever version
# happens to be current.
NEURODOCKER_VERSION=2.1.2

# Base image, qualified with its registry.  podman does not resolve short
# image names without an entry in registries.conf, and a qualified
# reference also works with apptainer.
BASE_IMAGE=docker.io/python:3.11-slim-bookworm

# Registry coordinates used by the optional push step
REGISTRY="${REGISTRY:-ghcr.io}"
REGISTRY_OWNER="${REGISTRY_OWNER:-}"
IMAGE_TAG="${IMAGE_TAG:-0.1.0}"

# Abort with an actionable message when uvx is unavailable
require_uvx() {
  if ! command -v uvx >/dev/null 2>&1; then
    echo "Error: 'uvx' was not found on PATH." >&2
    echo "" >&2
    echo "Install uv with:  curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
  fi
}

# Abort when podman is unavailable
require_podman() {
  if ! command -v podman >/dev/null 2>&1; then
    echo "Error: 'podman' was not found on PATH." >&2
    echo "" >&2
    echo "Install it with:  sudo apt-get install podman" >&2
    echo "On a shared machine, podman runs rootless and needs an" >&2
    echo "/etc/subuid and /etc/subgid entry for your user." >&2
    exit 1
  fi
}

# Abort when apptainer is unavailable
require_apptainer() {
  if ! command -v apptainer >/dev/null 2>&1; then
    echo "Error: 'apptainer' was not found on PATH." >&2
    echo "" >&2
    echo "See https://apptainer.org/docs/admin/main/installation.html" >&2
    exit 1
  fi
}

# Abort when uv.lock is missing, since the image build installs from it
require_lock() {
  if [[ ! -f uv.lock ]]; then
    echo "Error: 'uv.lock' was not found next to pyproject.toml." >&2
    echo "" >&2
    echo "The image build installs the locked versions, so create the" >&2
    echo "lock file first:  uv lock" >&2
    exit 1
  fi
}

# Abort when a push was requested without a registry namespace
require_registry_owner() {
  if [[ -z "$REGISTRY_OWNER" ]]; then
    echo "Error: REGISTRY_OWNER is not set, so the push destination is unknown." >&2
    echo "" >&2
    echo "Example:  REGISTRY_OWNER=vccn-lab IMAGE_TAG=0.1.0 $0 docker local push" >&2
    echo "Log in first:  podman login $REGISTRY" >&2
    exit 1
  fi
}

# Warn when apptainer would place multi-GB intermediates on the root
# filesystem instead of on local scratch
warn_apptainer_tmpdir() {
  if [[ -z "${APPTAINER_TMPDIR:-}" || -z "${APPTAINER_CACHEDIR:-}" ]]; then
    echo "  Note: APPTAINER_TMPDIR / APPTAINER_CACHEDIR are unset, so apptainer"
    echo "        will use /tmp and \$HOME.  Large images can fill the root"
    echo "        filesystem.  Point them at local scratch, for example:"
    echo "          export APPTAINER_TMPDIR=/raid/\$USER/apptainer-tmp"
    echo "          export APPTAINER_CACHEDIR=/raid/\$USER/apptainer-cache"
    echo ""
  fi
}

# Build the neurodocker argument list shared by both output formats
#
# Usage: generate_container <format>
#   format: "docker" or "singularity"
#
# Layer order keeps the dependency install separate from the source copy,
# so editing the analyses code reuses the cached dependency layer:
#   1. Base image and system packages
#   2. uv installer
#   3. pyproject.toml and uv.lock, then the dependencies on their own
#   4. Copy of the code, then the project itself
generate_container() {
  local format="$1"

  local args=(
    generate "$format"
    --base-image "$BASE_IMAGE"
    --pkg-manager apt
    --env DEBIAN_FRONTEND=noninteractive
    --install git curl build-essential gcc g++ nano
  )

  # --- uv, placed on PATH for every later layer and for the user ---
  args+=(--run 'curl -LsSf https://astral.sh/uv/install.sh | sh \
                && cp /root/.local/bin/uv /root/.local/bin/uvx /usr/local/bin/')

  # --- Dependencies, resolved by uv.lock rather than at build time ---
  #
  # UV_PROJECT_ENVIRONMENT puts the virtual environment in /opt instead of
  # in the source tree, so a bind mount over /home/$PROJECT at run time
  # does not hide it.  --no-install-project installs the dependencies
  # without the project, which is what keeps this layer cached when only
  # the analyses code changes.
  #
  # The variable is also set inline on every uv command below, and not
  # only declared here.  A declared variable reaches the later build
  # steps of a Dockerfile, where ENV applies to each following RUN, but
  # not those of a Singularity definition, where %environment is sourced
  # when the container starts and is absent while %post runs.  Relying on
  # the declaration alone put the environment in /home/$PROJECT/.venv
  # during the .sif build, after which the chmod below had no /opt path
  # to act on.
  args+=(--env UV_PROJECT_ENVIRONMENT="/opt/$PROJECT")
  args+=(--env VIRTUAL_ENV="/opt/$PROJECT")
  args+=(--env PATH="/opt/$PROJECT/bin:\$PATH")
  args+=(--copy pyproject.toml "/home/$PROJECT/pyproject.toml")
  args+=(--copy uv.lock "/home/$PROJECT/uv.lock")
  args+=(--run "cd /home/$PROJECT \
                && UV_PROJECT_ENVIRONMENT=/opt/$PROJECT \
                   uv sync --frozen --python 3.11 \
                     --extra notebooks --no-install-project \
                && rm -rf /root/.cache/uv")

  # --- Source copy, then the project itself ---
  #
  # The paths are listed one by one rather than copying the whole working
  # directory, for two reasons.  A directory given to COPY contributes its
  # contents and not itself, so each one needs its own destination.  And
  # ds-$PROJECT stays out of both images: apptainer does not read
  # .dockerignore, so an exclusion written there would keep the dataset
  # out of the OCI image while still copying it into the .sif.  The
  # dataset is bind-mounted at run time instead.
  #
  # A new top-level directory that the analyses import from has to be
  # added here as well.
  #
  # matlab/ and unreal/ hold sources for tools that are not in the
  # image: MATLAB with OpenFace and the AFAR toolbox, and the Unreal
  # Engine 5 Python interpreter. They are copied so that the image
  # carries the full record of how the data was produced, and are read
  # rather than run from inside the container.
  for path in "$PROJECT" analyzes tests matlab unreal README.md LICENSE; do
    args+=(--copy "$path" "/home/$PROJECT/$path")
  done
  args+=(--run "cd /home/$PROJECT \
                && UV_PROJECT_ENVIRONMENT=/opt/$PROJECT \
                   uv sync --frozen --python 3.11 --extra notebooks \
                && rm -rf /root/.cache/uv")

  # --- Environment marker, read by code that behaves differently in a
  #     container than on the host ---
  if [[ "$format" == "docker" ]]; then
    args+=(--env IS_DOCKER=1)
  else
    args+=(--env IS_SINGULARITY=1)
  fi

  # --- Jupyter, reachable from outside the container ---
  args+=(--env MPLCONFIGDIR=/tmp/matplotlib)
  args+=(--run "echo 'source /opt/$PROJECT/bin/activate' \
                >> /home/$PROJECT/.bashrc")
  args+=(--run "mkdir -p /home/$PROJECT/.jupyter \
                && echo c.ServerApp.ip = \\\"0.0.0.0\\\" \
                > /home/$PROJECT/.jupyter/jupyter_lab_config.py")

  # --- Jupyter kernel, registered inside the environment ---
  #
  # --sys-prefix writes the kernel under /opt/$PROJECT/share/jupyter, so
  # it belongs to the environment rather than to one account's home
  # directory.  --user would place it under the home of whoever the build
  # step ran as, which is the container user for the OCI image but root
  # for the .sif, where apptainer then runs as the calling user and never
  # looks there.
  args+=(--run "/opt/$PROJECT/bin/python -m ipykernel install --sys-prefix \
                --name $PROJECT --display-name 'Python ($PROJECT)'")
  args+=(--run "chmod -R a+rX /opt/$PROJECT")
  args+=(--workdir "/home/$PROJECT")

  # The remaining steps apply to the OCI image alone.
  #
  # A Singularity definition has no counterpart to USER: apptainer runs
  # as the calling user, and neurodocker renders a user switch as a bare
  # "su -" line in %post, which spawns a shell that exits again without
  # changing the user for the lines that follow.  Asking for the switch
  # would therefore add a step that reads as though it does something and
  # does not.  The same holds for the entrypoint, since "apptainer run"
  # is normally given the command to run.
  if [[ "$format" == "docker" ]]; then
    args+=(--user "$PROJECT")
    args+=(--user root)
    args+=(--run "chown -R $PROJECT /home/$PROJECT")
    args+=(--user "$PROJECT")
    args+=(--entrypoint "jupyter lab --port=8888 --no-browser --ip=0.0.0.0")
  fi

  uvx --from "neurodocker==${NEURODOCKER_VERSION}" neurodocker "${args[@]}"
}

generate_docker() { generate_container docker; }
generate_singularity() { generate_container singularity; }

# Build the OCI image from the generated Dockerfile with podman
build_podman() {
    echo "  -> Building OCI image '$PROJECT:local' from './Dockerfile' with podman..."
    echo "     This downloads the base image and installs all dependencies,"
    echo "     which can take several minutes."

    podman build -t "$PROJECT:local" -f Dockerfile .

    echo "  -> Image build completed"
    echo "     You can now run: podman run -p 8888:8888 $PROJECT:local"
}

# Build the Apptainer image from the generated definition file
#
# --fakeroot gives the build the appearance of root without needing it,
# which requires an /etc/subuid and /etc/subgid entry for the invoking
# user.  "apptainer build --help" lists the alternatives when that entry
# is missing.
build_apptainer() {
    warn_apptainer_tmpdir
    echo "  -> Building Apptainer image '$PROJECT.sif' from './Singularity.def'..."
    echo "     This can take several minutes."

    apptainer build --fakeroot --force "$PROJECT.sif" Singularity.def

    echo "  -> Apptainer image build completed"
    echo "     You can now run: apptainer run $PROJECT.sif"
}

# Remote reference used by both push steps
remote_ref() { echo "$REGISTRY/$REGISTRY_OWNER/$PROJECT:$IMAGE_TAG"; }

# Push the built OCI image to the registry
push_podman() {
    local remote
    remote="$(remote_ref)"

    echo "  -> Pushing '$PROJECT:local' to '$remote' with podman..."
    podman push "$PROJECT:local" "docker://$remote"
    echo "  -> Push completed: $remote"
    echo "     Consumers can run: podman pull $remote"
}

# Push the built SIF to the registry as an OCI artifact
#
# ORAS stores the SIF as an OCI artifact rather than as a runnable OCI
# image, so it is retrieved with "apptainer pull oras://..." and not with
# "podman pull".
push_apptainer() {
    local remote
    remote="$(remote_ref)"

    echo "  -> Pushing '$PROJECT.sif' to 'oras://$remote-sif'..."
    apptainer push "$PROJECT.sif" "oras://$remote-sif"
    echo "  -> Push completed: oras://$remote-sif"
    echo "     Consumers can run: apptainer pull oras://$remote-sif"
}

show_usage() {
    echo "Usage: $0 [docker|singularity|both] [local] [push]"
    echo ""
    echo "DESCRIPTION:"
    echo "  Generates the container definitions for $PROJECT with"
    echo "  neurodocker, run through uvx so that no container runtime is"
    echo "  needed to generate them.  Inside the images, 'uv sync --frozen'"
    echo "  installs the versions recorded in uv.lock."
    echo ""
    echo "  'local' builds the images: the OCI image with podman and the"
    echo "  .sif with apptainer --fakeroot.  Neither needs a root daemon."
    echo "  The container workflow in CI builds and publishes the OCI"
    echo "  image from the same generated Dockerfile."
    echo ""
    echo "ARGUMENTS:"
    echo "  docker       Generate Dockerfile only"
    echo "  singularity  Generate Singularity.def only"
    echo "  both         Generate both files (default if no args)"
    echo "  local        Also build the image(s) after generating"
    echo "  push         Also push the built image(s) to \$REGISTRY"
    echo ""
    echo "ENVIRONMENT:"
    echo "  REGISTRY        Registry to push to (default: ghcr.io)"
    echo "  REGISTRY_OWNER  Namespace within the registry, required by push"
    echo "  IMAGE_TAG       Tag to push (default: 0.1.0)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                      # Generate both definition files"
    echo "  $0 docker               # Generate Dockerfile only"
    echo "  $0 singularity local    # Generate Singularity.def, build the .sif"
    echo "  $0 both local           # Generate both files, build both images"
    echo "  REGISTRY_OWNER=vccn-lab IMAGE_TAG=0.1.0 $0 docker local push"
    echo ""
    echo "REQUIREMENTS:"
    echo "  - uv, so that uvx can fetch neurodocker ${NEURODOCKER_VERSION}"
    echo "  - a committed uv.lock, which the image build installs from;"
    echo "    create or refresh it with 'uv lock'"
    echo "  - podman, for the OCI image build and push"
    echo "  - apptainer, for the .sif build and push"
    echo "  - an /etc/subuid entry for your user, for rootless podman and"
    echo "    for apptainer --fakeroot"
    echo ""
    echo "OUTPUT FILES:"
    echo "  - Dockerfile: also consumed by the CI container workflow"
    echo "  - Singularity.def: Apptainer/Singularity definition"
    echo "  - $PROJECT:local: OCI image (with 'local')"
    echo "  - $PROJECT.sif: Apptainer image (with 'local')"
}

echo "=== $PROJECT container generation script ==="
echo ""

GENERATE_DOCKER=false
GENERATE_SINGULARITY=false
BUILD_LOCAL=false
PUSH_IMAGES=false

echo "Parsing command line arguments..."

# Default behaviour: generate both definition files
if [ $# -eq 0 ]; then
    echo "  -> No arguments provided, generating both definition files"
    GENERATE_DOCKER=true
    GENERATE_SINGULARITY=true
fi

for arg in "$@"; do
    echo "  -> Processing argument: $arg"
    case $arg in
        docker)
            echo "     Will generate Dockerfile"
            GENERATE_DOCKER=true
            ;;
        singularity)
            echo "     Will generate Singularity.def"
            GENERATE_SINGULARITY=true
            ;;
        both)
            echo "     Will generate both definition files"
            GENERATE_DOCKER=true
            GENERATE_SINGULARITY=true
            ;;
        local)
            echo "     Will build the image(s) after generating"
            BUILD_LOCAL=true
            ;;
        push)
            echo "     Will push the built image(s)"
            PUSH_IMAGES=true
            ;;
        help|--help|-h)
            echo ""
            show_usage
            exit 0
            ;;
        *)
            echo "     Error: unknown argument '$arg'"
            echo ""
            echo "Valid arguments: docker, singularity, both, local, push, help"
            echo ""
            show_usage
            exit 1
            ;;
    esac
done

if [ "$GENERATE_DOCKER" = false ] && [ "$GENERATE_SINGULARITY" = false ]; then
    echo ""
    echo "Error: no generation options selected.  At least one of 'docker',"
    echo "'singularity' or 'both' is required."
    echo ""
    show_usage
    exit 1
fi

# A push needs an image, which only the build phase produces
if [ "$PUSH_IMAGES" = true ] && [ "$BUILD_LOCAL" = false ]; then
    echo ""
    echo "Error: 'push' sends the built image(s) to the registry and"
    echo "therefore needs 'local' as well."
    echo ""
    show_usage
    exit 1
fi

echo ""
echo "Configuration summary:"
echo "  - Generate Dockerfile: $GENERATE_DOCKER"
echo "  - Generate Singularity.def: $GENERATE_SINGULARITY"
echo "  - Build image(s) locally: $BUILD_LOCAL"
echo "  - Push image(s): $PUSH_IMAGES"
echo ""

# Check every tool the selected steps need before doing any work, so that
# a missing one is reported before the first download rather than after it
require_uvx
require_lock
if [ "$BUILD_LOCAL" = true ]; then
    if [ "$GENERATE_DOCKER" = true ]; then
        require_podman
    fi
    if [ "$GENERATE_SINGULARITY" = true ]; then
        require_apptainer
    fi
fi
if [ "$PUSH_IMAGES" = true ]; then
    require_registry_owner
fi

echo "=== GENERATION PHASE ==="
echo ""

if [ "$GENERATE_DOCKER" = true ]; then
    echo "Generating Dockerfile..."
    generate_docker > Dockerfile
    echo "Dockerfile written ($(wc -l < Dockerfile) lines)"
    echo ""
fi

if [ "$GENERATE_SINGULARITY" = true ]; then
    echo "Generating Singularity.def..."
    generate_singularity > Singularity.def
    echo "Singularity.def written ($(wc -l < Singularity.def) lines)"
    echo ""
fi

if [ "$BUILD_LOCAL" = true ]; then
    echo "=== BUILD PHASE ==="
    echo ""

    if [ "$GENERATE_DOCKER" = true ]; then
        build_podman
        echo ""
        echo "OCI image information:"
        podman images "$PROJECT:local" \
            --format "  Size: {{.Size}}, Created: {{.CreatedSince}}"
        echo ""
    fi

    if [ "$GENERATE_SINGULARITY" = true ]; then
        build_apptainer
        echo ""
        if [ -f "$PROJECT.sif" ]; then
            echo "Apptainer image information:"
            echo "  Size: $(du -h "$PROJECT.sif" | cut -f1)"
            echo "  Location: $(pwd)/$PROJECT.sif"
        fi
        echo ""
    fi
else
    echo "=== GENERATION COMPLETE ==="
    echo ""
    echo "Definition files generated; no image was built."
    echo ""
    echo "To build the images later:"
    if [ "$GENERATE_DOCKER" = true ]; then
        echo "  - podman build -t $PROJECT:local ."
    fi
    if [ "$GENERATE_SINGULARITY" = true ]; then
        echo "  - apptainer build --fakeroot $PROJECT.sif Singularity.def"
    fi
    echo "  - or run this script again with 'local'"
    echo ""
fi

if [ "$PUSH_IMAGES" = true ]; then
    echo "=== PUSH PHASE ==="
    echo ""
    if [ "$GENERATE_DOCKER" = true ]; then
        push_podman
    fi
    if [ "$GENERATE_SINGULARITY" = true ]; then
        push_apptainer
    fi
    echo ""
fi

echo "=== SUMMARY ==="
echo ""
echo "Generated files:"
if [ "$GENERATE_DOCKER" = true ]; then
    echo "  Dockerfile ($(wc -l < Dockerfile) lines)"
fi
if [ "$GENERATE_SINGULARITY" = true ]; then
    echo "  Singularity.def ($(wc -l < Singularity.def) lines)"
fi
if [ "$BUILD_LOCAL" = true ]; then
    echo ""
    echo "Built images:"
    if [ "$GENERATE_DOCKER" = true ]; then
        echo "  $PROJECT:local"
    fi
    if [ "$GENERATE_SINGULARITY" = true ] && [ -f "$PROJECT.sif" ]; then
        echo "  $PROJECT.sif"
    fi
fi
echo ""
echo "Script execution completed at $(date)"
