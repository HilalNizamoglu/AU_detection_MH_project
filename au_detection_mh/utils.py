"""Dataset constants and loaders.

The dataset in ``ds-au_detection_mh`` is indexed by avatar and
animation. Every video contributes four matrices of frames by action
units: the rig activation read back from Unreal Engine, which is the
ground truth, and one prediction matrix per detector. Each is stored as
a MATLAB ``.mat`` file whose variable name differs by source, which is
what ``MAT_SOURCES`` records.
"""

import os

import numpy as np
import pandas as pd
from scipy.io import loadmat

# The four MetaHuman presets the animations were built on, in the order
# the published tables and figures use.
AVATARS = ("Ada", "Garry", "Cooper", "Pia")

# The 18 animations: 11 single action units, then 7 in which the brows
# move together with another action unit.
ANIMATIONS = (
    "AU01",
    "AU02",
    "AU04",
    "AU06",
    "AU07",
    "AU10",
    "AU12",
    "AU14",
    "AU15",
    "AU17",
    "AU23",
    "browsAll",
    "browsAU10",
    "browsAU12",
    "browsAU14",
    "browsAU15",
    "browsAU17",
    "browsAU23",
)

# The single-action-unit animations. These also name the 11 columns of
# every matrix in the dataset, so they are the labels a false detection
# is reported against.
AU_ONLY_ANIMATIONS = ANIMATIONS[:11]

# The three detectors compared against the rig ground truth.
DETECTORS = ("OF", "AFAR", "pyFEAT")

# Source -> (filename infix, variable name inside the .mat file).
# "actual" is the rig ground truth; the rest are detector predictions.
MAT_SOURCES = {
    "actual": ("actualValues", "actual_mat"),
    "OF": ("OFpred", "normed_OF_pred"),
    "AFAR": ("AFARpred", "AFAR_pred"),
    "pyFEAT": ("PYFEATpred", "PYFEAT_pred"),
}

LANDMARK_SUFFIX = "landmark_displacement.csv"


def _check_source(source):
    """Return the entry for ``source``, or raise naming the valid ones."""
    if source not in MAT_SOURCES:
        raise ValueError(
            f"unknown source {source!r}; expected one of "
            f"{', '.join(MAT_SOURCES)}"
        )
    return MAT_SOURCES[source]


def matrix_filename(avatar, animation, source):
    """Name of the ``.mat`` file holding one matrix.

    Parameters
    ----------
    avatar : str
        One of :data:`AVATARS`.
    animation : str
        One of :data:`ANIMATIONS`.
    source : str
        One of the keys of :data:`MAT_SOURCES`.

    Returns
    -------
    str
    """
    infix, _ = _check_source(source)
    return f"{avatar}_{infix}_anim_{animation}.mat"


def load_matrix(data_dir, avatar, animation, source):
    """Read one frames-by-AUs matrix from the dataset.

    Parameters
    ----------
    data_dir : str or os.PathLike
        Directory holding the ``.mat`` files, normally
        ``ds-au_detection_mh/sourcedata``.
    avatar, animation, source : str
        As for :func:`matrix_filename`.

    Returns
    -------
    numpy.ndarray
        Frames by action units.

    Raises
    ------
    FileNotFoundError
        If the file is not in ``data_dir``.
    KeyError
        If the file does not hold the variable the source names.
    """
    _, variable = _check_source(source)
    path = os.path.join(data_dir, matrix_filename(avatar, animation, source))
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    contents = loadmat(path)
    if variable not in contents:
        raise KeyError(
            f"{path} does not hold the variable {variable!r} that "
            f"source {source!r} is stored under"
        )
    return contents[variable]


def load_video(data_dir, avatar, animation, sources=None):
    """Read every source for one avatar and animation.

    Parameters
    ----------
    data_dir : str or os.PathLike
        Directory holding the ``.mat`` files.
    avatar, animation : str
        As for :func:`matrix_filename`.
    sources : iterable of str, optional
        Which sources to read. Defaults to all of
        :data:`MAT_SOURCES`.

    Returns
    -------
    dict of str to numpy.ndarray
        One matrix per source, keyed by source name.
    """
    if sources is None:
        sources = tuple(MAT_SOURCES)
    return {
        source: load_matrix(data_dir, avatar, animation, source)
        for source in sources
    }


def landmark_filename(avatar, animation):
    """Name of the landmark displacement file for one video."""
    return f"{avatar}_{animation}_{LANDMARK_SUFFIX}"


def load_landmark_displacement(derivatives_dir, avatar, animation):
    """Read one landmark displacement trace.

    Parameters
    ----------
    derivatives_dir : str or os.PathLike
        Directory holding the displacement files, normally
        ``ds-au_detection_mh/derivatives/landmark-displacement``.
    avatar, animation : str
        As for :func:`landmark_filename`.

    Returns
    -------
    numpy.ndarray
        Frames by landmarks. The files carry no header row.

    Raises
    ------
    FileNotFoundError
        If the file is not in ``derivatives_dir``.
    """
    path = os.path.join(derivatives_dir, landmark_filename(avatar, animation))
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    return np.asarray(pd.read_csv(path, header=None).values)
