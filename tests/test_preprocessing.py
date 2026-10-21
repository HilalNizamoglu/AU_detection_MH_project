"""Tests for thresholding and the confusion counts.

The worked example below is used by several tests and by
``test_analyses``. With a threshold of 0.2 its four cells fall one into
each of the four confusion categories:

======  ==========  ============  ========
Cell    actual      predicted     Category
======  ==========  ============  ========
(0, 0)  0.5 (high)  0.9 (high)    TP
(0, 1)  0.0 (low)   0.8 (high)    FP
(1, 0)  0.0 (low)   0.1 (low)     TN
(1, 1)  0.3 (high)  0.1 (low)     FN
======  ==========  ============  ========
"""

import numpy as np
import pytest

from au_detection_mh import preprocessing

THRESHOLD = 0.2
ACTUAL = np.array([[0.5, 0.0], [0.0, 0.3]])
PREDICTED = np.array([[0.9, 0.8], [0.1, 0.1]])
LABELS = ("AU01", "AU02")


def test_binarize_splits_on_a_strict_threshold():
    """A value equal to the threshold counts as inactive."""
    matrix = np.array([[0.1, 0.2], [0.21, 0.9]])
    np.testing.assert_array_equal(
        preprocessing.binarize(matrix, 0.2),
        np.array([[0, 0], [1, 1]]),
    )


def test_binarize_returns_integers():
    """The output feeds sklearn's roc_curve, which wants labels."""
    result = preprocessing.binarize(ACTUAL, THRESHOLD)
    assert result.dtype == np.dtype(int)


def test_binarize_leaves_the_input_untouched():
    """Thresholding does not modify the matrix it was given."""
    matrix = ACTUAL.copy()
    preprocessing.binarize(matrix, THRESHOLD)
    np.testing.assert_allclose(matrix, ACTUAL)


def test_confusion_counts_assigns_each_cell_one_category():
    """The worked example gives one cell to each category."""
    counts = preprocessing.confusion_counts(ACTUAL, PREDICTED, THRESHOLD)
    assert counts["TP"] == 1
    assert counts["FP"] == 1
    assert counts["TN"] == 1
    assert counts["FN"] == 1


def test_confusion_counts_sum_to_the_number_of_cells():
    """Every cell is counted exactly once."""
    counts = preprocessing.confusion_counts(ACTUAL, PREDICTED, THRESHOLD)
    total = counts["TP"] + counts["FP"] + counts["TN"] + counts["FN"]
    assert total == ACTUAL.size


def test_confusion_counts_records_false_detections_by_column():
    """A false positive records which AU column it fell in."""
    counts = preprocessing.confusion_counts(
        ACTUAL, PREDICTED, THRESHOLD, labels=LABELS
    )
    assert counts["false_detections"] == ["AU02"]


def test_confusion_counts_falls_back_to_column_indices():
    """Without labels, a false detection is reported by index."""
    counts = preprocessing.confusion_counts(ACTUAL, PREDICTED, THRESHOLD)
    assert counts["false_detections"] == [1]


def test_confusion_counts_records_one_entry_per_false_positive():
    """Two false positives in one column give two entries."""
    actual = np.array([[0.0, 0.0], [0.0, 0.0]])
    predicted = np.array([[0.9, 0.0], [0.9, 0.0]])
    counts = preprocessing.confusion_counts(
        actual, predicted, THRESHOLD, labels=LABELS
    )
    assert counts["FP"] == 2
    assert counts["false_detections"] == ["AU01", "AU01"]


def test_confusion_counts_rejects_mismatched_shapes():
    """A prediction matrix of another shape is an error."""
    with pytest.raises(ValueError, match="shape"):
        preprocessing.confusion_counts(ACTUAL, np.zeros((3, 2)), THRESHOLD)


def test_confusion_counts_rejects_mismatched_labels():
    """One label per column, or none at all."""
    with pytest.raises(ValueError, match="label"):
        preprocessing.confusion_counts(
            ACTUAL, PREDICTED, THRESHOLD, labels=("AU01",)
        )


def test_confusion_percentages_are_whole_percents_of_the_cells():
    """Each category as a rounded percentage of the matrix."""
    counts = preprocessing.confusion_counts(ACTUAL, PREDICTED, THRESHOLD)
    percentages = preprocessing.confusion_percentages(counts, ACTUAL.size)
    assert percentages == {
        "TP_perc": 25,
        "FP_perc": 25,
        "TN_perc": 25,
        "FN_perc": 25,
    }


def test_confusion_percentages_rejects_an_empty_matrix():
    """A zero cell count has no percentage to report."""
    counts = {"TP": 0, "FP": 0, "TN": 0, "FN": 0}
    with pytest.raises(ValueError, match="zero"):
        preprocessing.confusion_percentages(counts, 0)
