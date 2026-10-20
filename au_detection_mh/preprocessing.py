"""Thresholding a prediction matrix against the rig ground truth.

A cell of the ground truth counts as an active action unit when the rig
activation exceeds the threshold, and a cell of a prediction matrix
counts as a detection on the same test. Comparing the two cell by cell
gives the confusion counts the reported rates are computed from.
"""

import numpy as np


def binarize(matrix, threshold):
    """Mark the cells of ``matrix`` that exceed ``threshold``.

    The test is strict, so a value equal to the threshold counts as
    inactive.

    Parameters
    ----------
    matrix : array_like
        Frames by action units.
    threshold : float
        Activation above which a cell counts as active.

    Returns
    -------
    numpy.ndarray of int
        Ones and zeros, the same shape as ``matrix``.
    """
    return np.where(np.asarray(matrix) > threshold, 1, 0)


def _check_inputs(actual, predicted, labels):
    """Validate the shapes of a ground truth and prediction pair."""
    actual = np.asarray(actual)
    predicted = np.asarray(predicted)
    if actual.shape != predicted.shape:
        raise ValueError(
            f"actual and predicted have shape {actual.shape} and "
            f"{predicted.shape}; they have to match"
        )
    if labels is not None and len(labels) != actual.shape[1]:
        raise ValueError(
            f"{len(labels)} labels for {actual.shape[1]} columns; pass "
            "one label per column, or none"
        )
    return actual, predicted


def confusion_counts(actual, predicted, threshold, labels=None):
    """Count the four confusion categories over every cell.

    A cell is a true positive when both the rig activation and the
    prediction exceed ``threshold``, a false negative when only the rig
    activation does, a false positive when only the prediction does, and
    a true negative when neither does.

    Parameters
    ----------
    actual : array_like
        Rig activation, frames by action units.
    predicted : array_like
        Detector output, the same shape as ``actual``.
    threshold : float
        Activation above which a cell counts as active.
    labels : sequence of str, optional
        One label per column, used to report which action unit a false
        positive fell in. Column indices are reported when omitted.

    Returns
    -------
    dict
        ``TP``, ``FP``, ``TN`` and ``FN`` as integers, and
        ``false_detections`` as one entry per false positive.

    Raises
    ------
    ValueError
        If the two matrices differ in shape, or if ``labels`` does not
        have one entry per column.
    """
    actual, predicted = _check_inputs(actual, predicted, labels)
    actual_active = actual > threshold
    predicted_active = predicted > threshold

    false_positive = ~actual_active & predicted_active
    columns = np.nonzero(false_positive)[1]
    if labels is None:
        false_detections = [int(column) for column in columns]
    else:
        false_detections = [labels[column] for column in columns]

    return {
        "TP": int(np.count_nonzero(actual_active & predicted_active)),
        "FP": int(np.count_nonzero(false_positive)),
        "TN": int(np.count_nonzero(~actual_active & ~predicted_active)),
        "FN": int(np.count_nonzero(actual_active & ~predicted_active)),
        "false_detections": false_detections,
    }


def confusion_percentages(counts, n_cells):
    """Express the confusion counts as whole percentages of the matrix.

    Parameters
    ----------
    counts : dict
        As returned by :func:`confusion_counts`.
    n_cells : int
        Number of cells the counts were taken over, which is the size of
        the matrix.

    Returns
    -------
    dict
        ``TP_perc``, ``FP_perc``, ``TN_perc`` and ``FN_perc``, each
        rounded to a whole percent.

    Raises
    ------
    ValueError
        If ``n_cells`` is zero.
    """
    if n_cells == 0:
        raise ValueError(
            "n_cells is zero, so there is no percentage to report"
        )
    return {
        f"{key}_perc": round(counts[key] / n_cells * 100)
        for key in ("TP", "FP", "TN", "FN")
    }
