"""Tests for the dataset constants and loaders in au_detection_mh.utils.

The loaders are exercised against matrices written into ``tmp_path``
rather than against ``ds-au_detection_mh``, so that these pass in a
checkout where the dataset has not been retrieved.
"""

import numpy as np
import pytest
from scipy.io import savemat

from au_detection_mh import utils


@pytest.fixture
def matrix():
    """A frames-by-AUs matrix with a distinguishable value per cell."""
    return np.arange(12, dtype=float).reshape(4, 3) / 11.0


@pytest.fixture
def sourcedata(tmp_path, matrix):
    """A sourcedata directory holding one video for one avatar."""
    directory = tmp_path / "sourcedata"
    directory.mkdir()
    for infix, variable in utils.MAT_SOURCES.values():
        savemat(
            directory / f"Ada_{infix}_anim_AU01.mat",
            {variable: matrix},
        )
    return directory


def test_avatars_are_the_four_metahuman_presets():
    """The dataset is indexed by four avatars, in the published order."""
    assert utils.AVATARS == ("Ada", "Garry", "Cooper", "Pia")


def test_animations_cover_eleven_aus_and_seven_brow_combinations():
    """There are 18 animations, the first 11 being single AUs."""
    assert len(utils.ANIMATIONS) == 18
    assert len(utils.AU_ONLY_ANIMATIONS) == 11
    assert utils.AU_ONLY_ANIMATIONS == utils.ANIMATIONS[:11]
    assert all(name.startswith("AU") for name in utils.AU_ONLY_ANIMATIONS)
    assert all(name.startswith("brows") for name in utils.ANIMATIONS[11:])


def test_detectors_are_the_three_compared_tools():
    """The three detectors, excluding the rig ground truth."""
    assert utils.DETECTORS == ("OF", "AFAR", "pyFEAT")
    assert "actual" not in utils.DETECTORS
    assert set(utils.DETECTORS) < set(utils.MAT_SOURCES)


def test_mat_sources_name_a_file_infix_and_a_variable():
    """Every source maps to the filename infix and the .mat variable."""
    assert utils.MAT_SOURCES["actual"] == ("actualValues", "actual_mat")
    assert utils.MAT_SOURCES["OF"] == ("OFpred", "normed_OF_pred")
    assert utils.MAT_SOURCES["AFAR"] == ("AFARpred", "AFAR_pred")
    assert utils.MAT_SOURCES["pyFEAT"] == ("PYFEATpred", "PYFEAT_pred")


def test_matrix_filename_follows_the_dataset_convention():
    """The filename is avatar, source infix and animation, joined."""
    assert (
        utils.matrix_filename("Ada", "AU01", "actual")
        == "Ada_actualValues_anim_AU01.mat"
    )
    assert (
        utils.matrix_filename("Pia", "browsAll", "OF")
        == "Pia_OFpred_anim_browsAll.mat"
    )


def test_matrix_filename_rejects_an_unknown_source():
    """An unknown source names the valid ones in the error."""
    with pytest.raises(ValueError, match="pyFEAT"):
        utils.matrix_filename("Ada", "AU01", "openface")


def test_load_matrix_returns_the_matrix_the_file_holds(sourcedata, matrix):
    """The loader reads the variable the source's convention names."""
    loaded = utils.load_matrix(sourcedata, "Ada", "AU01", "actual")
    assert isinstance(loaded, np.ndarray)
    assert loaded.shape == matrix.shape
    np.testing.assert_allclose(loaded, matrix)


def test_load_matrix_rejects_an_unknown_source(sourcedata):
    """The source is validated before the filesystem is touched."""
    with pytest.raises(ValueError, match="pyFEAT"):
        utils.load_matrix(sourcedata, "Ada", "AU01", "openface")


def test_load_matrix_raises_for_a_missing_file(sourcedata):
    """A video that is not in the directory is an error, not a None."""
    with pytest.raises(FileNotFoundError):
        utils.load_matrix(sourcedata, "Garry", "AU01", "actual")


def test_load_matrix_raises_when_the_variable_is_absent(tmp_path, matrix):
    """A .mat under the right name but the wrong variable is an error."""
    savemat(tmp_path / "Ada_actualValues_anim_AU01.mat", {"other": matrix})
    with pytest.raises(KeyError, match="actual_mat"):
        utils.load_matrix(tmp_path, "Ada", "AU01", "actual")


def test_load_video_returns_one_matrix_per_source(sourcedata):
    """All four sources for one avatar and animation, keyed by source."""
    video = utils.load_video(sourcedata, "Ada", "AU01")
    assert set(video) == set(utils.MAT_SOURCES)
    assert all(v.shape == (4, 3) for v in video.values())


def test_load_video_honours_a_subset_of_sources(sourcedata):
    """Asking for two sources reads two files and no others."""
    video = utils.load_video(
        sourcedata, "Ada", "AU01", sources=("actual", "OF")
    )
    assert set(video) == {"actual", "OF"}


def test_landmark_filename_follows_the_derivative_convention():
    """Landmark displacement files are named avatar, animation, suffix."""
    assert (
        utils.landmark_filename("Cooper", "browsAU17")
        == "Cooper_browsAU17_landmark_displacement.csv"
    )


def test_load_landmark_displacement_reads_a_headerless_csv(tmp_path):
    """The displacement CSVs carry no header row."""
    path = tmp_path / utils.landmark_filename("Ada", "AU01")
    path.write_text("0,0,0\n1.5,2.5,3.5\n")
    loaded = utils.load_landmark_displacement(tmp_path, "Ada", "AU01")
    assert loaded.shape == (2, 3)
    np.testing.assert_allclose(loaded[1], [1.5, 2.5, 3.5])


def test_load_landmark_displacement_raises_for_a_missing_file(tmp_path):
    """A missing displacement file is an error, not an empty frame."""
    with pytest.raises(FileNotFoundError):
        utils.load_landmark_displacement(tmp_path, "Pia", "AU23")


@pytest.fixture
def landmark_mapping(tmp_path):
    """An AU-to-landmark mapping in the layout MATLAB wrote it in."""
    rows = [
        ("AU01", "inner-EB-raiser", [1, 2, 3]),
        ("AU02", "outer-EB-raiser", [2, 4]),
    ]
    cells = np.empty((len(rows), 3), dtype=object)
    for index, (animation, description, landmarks) in enumerate(rows):
        cells[index, 0] = np.array([animation])
        cells[index, 1] = np.array([description])
        cells[index, 2] = np.array([landmarks], dtype=np.uint8)
    savemat(tmp_path / "AU_landm_mapping.mat", {"AU_landm_mapping": cells})
    return tmp_path


def test_load_landmark_mapping_keys_on_the_animation_name(
    landmark_mapping,
):
    """One entry per animation, keyed by the name in the first column."""
    mapping = utils.load_landmark_mapping(landmark_mapping)
    assert set(mapping) == {"AU01", "AU02"}


def test_load_landmark_mapping_converts_to_zero_based_indices(
    landmark_mapping,
):
    """MATLAB counts landmarks from one, numpy from zero."""
    mapping = utils.load_landmark_mapping(landmark_mapping)
    np.testing.assert_array_equal(mapping["AU01"], [0, 1, 2])
    np.testing.assert_array_equal(mapping["AU02"], [1, 3])
    assert mapping["AU01"].dtype == np.dtype(int)


def test_load_landmark_mapping_raises_for_a_missing_file(tmp_path):
    """The mapping is required, so its absence is an error."""
    with pytest.raises(FileNotFoundError):
        utils.load_landmark_mapping(tmp_path)
