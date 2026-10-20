"""The measures the paper reports.

Three questions are asked of each detector, and this module carries one
group of functions per question:

Binary classification performance
    Whether the detector reports the action unit that was animated.
    :func:`classification_metrics` scores one video and
    :func:`classification_metrics_table` assembles the table over every
    avatar and animation.

Temporal alignment
    Whether it reports it at the right time.
    :func:`zero_lag_cross_correlation` compares a prediction with the
    rig ground truth, and :func:`cross_correlation_profile` gives the
    same comparison across lags.

Landmark displacement
    Whether the facial motion it responds to is in the right place.
    :func:`pairwise_landmark_correlations` compares the motion of one
    avatar with another, and :func:`active_inactive_ratio` compares the
    landmarks an animation targets with the rest.

The functions return arrays, dictionaries and ``pandas`` objects.
Plotting and hypothesis testing are left to the notebooks in
``analyzes``.
"""

import warnings

import numpy as np
import pandas as pd
from scipy.signal import correlate, correlation_lags
from scipy.stats import pearsonr
from sklearn.metrics import auc, roc_curve

from au_detection_mh.preprocessing import (
    binarize,
    confusion_counts,
    confusion_percentages,
)
from au_detection_mh.utils import (
    ANIMATIONS,
    AU_ONLY_ANIMATIONS,
    AVATARS,
    DETECTORS,
    load_landmark_displacement,
    load_video,
)


def _rate(numerator, denominator_parts, name):
    """Divide ``numerator`` by a sum, warning when the sum is zero."""
    denominator = sum(denominator_parts)
    if denominator == 0:
        warnings.warn(
            f"{name} is undefined: its denominator is zero",
            UserWarning,
            stacklevel=3,
        )
        return None
    return numerator / denominator


def sensitivity(tp, fn):
    """True positive rate: detections among the animated action units."""
    return _rate(tp, (tp, fn), "sensitivity")


def false_positive_rate(fp, tn):
    """Detections among the action units that were not animated."""
    return _rate(fp, (fp, tn), "false positive rate")


def specificity(tn, fp):
    """True negative rate: the complement of the false positive rate."""
    return _rate(tn, (tn, fp), "specificity")


def precision(tp, fp):
    """Share of the detections that were of an animated action unit."""
    return _rate(tp, (tp, fp), "precision")


def f1_score(sensitivity_value, precision_value):
    """Harmonic mean of sensitivity and precision.

    Returns 0.0 and warns when either input is ``None``, which happens
    when the rate it came from had an empty denominator, and when both
    are zero.
    """
    if sensitivity_value is None or precision_value is None:
        warnings.warn(
            "F1 score is undefined: sensitivity or precision is None",
            UserWarning,
            stacklevel=2,
        )
        return 0.0
    total = sensitivity_value + precision_value
    if total == 0:
        warnings.warn(
            "F1 score is undefined: sensitivity and precision are both "
            "zero",
            UserWarning,
            stacklevel=2,
        )
        return 0.0
    return 2 * (sensitivity_value * precision_value) / total


def roc_auc(actual, predicted, threshold):
    """Area under the ROC curve for one video.

    The threshold is applied to the rig ground truth only, to label each
    cell active or inactive. The prediction enters as a continuous
    score, so the area is unaffected by where the detector's own
    decision threshold would sit.

    Parameters
    ----------
    actual : array_like
        Rig activation, frames by action units.
    predicted : array_like
        Detector output, the same shape as ``actual``.
    threshold : float
        Activation above which a cell of ``actual`` counts as active.

    Returns
    -------
    float
    """
    labels = binarize(actual, threshold).flatten()
    scores = np.asarray(predicted, dtype=float).flatten()
    curve_fpr, curve_tpr, _ = roc_curve(labels, scores)
    return float(auc(curve_fpr, curve_tpr))


def classification_metrics(
    actual, predicted, threshold, labels=AU_ONLY_ANIMATIONS
):
    """Score one video against the rig ground truth.

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
        positive fell in. Defaults to the single-AU animation names,
        which is what the columns of the dataset's matrices are.

    Returns
    -------
    dict
        The confusion counts and their percentages, the true positive
        and false positive rates, the F1 score and the AUC.
    """
    counts = confusion_counts(actual, predicted, threshold, labels=labels)
    row = dict(counts)
    row.update(confusion_percentages(counts, np.asarray(actual).size))
    true_positive_rate = sensitivity(counts["TP"], counts["FN"])
    row["TPR"] = true_positive_rate
    row["FPR"] = false_positive_rate(counts["FP"], counts["TN"])
    row["F1_score"] = f1_score(
        true_positive_rate, precision(counts["TP"], counts["FP"])
    )
    row["AUC"] = roc_auc(actual, predicted, threshold)
    return row


def _check_detector(detector):
    """Raise unless ``detector`` is one of the three compared tools."""
    if detector not in DETECTORS:
        raise ValueError(
            f"unknown detector {detector!r}; expected one of "
            f"{', '.join(DETECTORS)}. The source 'actual' is the rig "
            "ground truth, not a detector to be scored against itself"
        )


def classification_metrics_table(
    data_dir,
    detector,
    threshold,
    avatars=AVATARS,
    animations=ANIMATIONS,
    labels=AU_ONLY_ANIMATIONS,
):
    """Score every video for one detector.

    Parameters
    ----------
    data_dir : str or os.PathLike
        Directory holding the ``.mat`` files.
    detector : str
        One of :data:`au_detection_mh.utils.DETECTORS`.
    threshold : float
        Activation above which a cell counts as active.
    avatars, animations : sequence of str, optional
        Which videos to score. Default to the full dataset.
    labels : sequence of str, optional
        As for :func:`classification_metrics`.

    Returns
    -------
    pandas.DataFrame
        One row per avatar and animation, those two naming the first
        columns, followed by the metrics.

    Raises
    ------
    ValueError
        If ``detector`` is not one of the three compared tools.
    """
    _check_detector(detector)
    rows = []
    for avatar in avatars:
        for animation in animations:
            video = load_video(
                data_dir,
                avatar,
                animation,
                sources=("actual", detector),
            )
            row = {"avatar": avatar, "animation": animation}
            row.update(
                classification_metrics(
                    video["actual"],
                    video[detector],
                    threshold,
                    labels=labels,
                )
            )
            rows.append(row)
    return pd.DataFrame(rows)


def _as_trace(matrix):
    """Flatten a frames-by-AUs matrix into one concatenated trace.

    Column-major order keeps each action unit's time course contiguous,
    which is what the lags of a cross-correlation are then over.
    """
    return np.asarray(matrix, dtype=float).flatten(order="F")


def cross_correlation_profile(actual, predicted, max_lag=None):
    """Cross-correlate a prediction with the rig ground truth over lags.

    Both inputs are mean-centred and the correlation is normalised by
    the trace length and the two standard deviations, so the value at
    lag zero is Pearson's r.

    Parameters
    ----------
    actual : array_like
        Rig activation, frames by action units, or a flat trace.
    predicted : array_like
        Detector output, the same shape as ``actual``.
    max_lag : int, optional
        Largest lag to report, in frames. Defaults to a quarter of the
        trace length, as in the published run.

    Returns
    -------
    lags : numpy.ndarray of int
        The lags reported, from ``-max_lag`` to ``max_lag``.
    correlation : numpy.ndarray of float
        The correlation at each of those lags.

    Raises
    ------
    ValueError
        If the two inputs differ in size.
    """
    first = _as_trace(actual)
    second = _as_trace(predicted)
    if first.size != second.size:
        raise ValueError(
            f"actual and predicted flatten to {first.size} and "
            f"{second.size} samples; they have to match"
        )
    correlation = correlate(
        first - first.mean(), second - second.mean(), mode="full"
    )
    correlation = correlation / (first.size * first.std() * second.std())
    lags = correlation_lags(first.size, second.size, mode="full")
    if max_lag is None:
        max_lag = first.size // 4
    mask = np.abs(lags) <= max_lag
    return lags[mask], correlation[mask]


def zero_lag_cross_correlation(actual, predicted):
    """Cross-correlation of a prediction with the ground truth at lag 0.

    Parameters
    ----------
    actual, predicted : array_like
        As for :func:`cross_correlation_profile`.

    Returns
    -------
    float
    """
    lags, correlation = cross_correlation_profile(actual, predicted)
    return float(correlation[lags == 0][0])


def cross_correlation_table(
    data_dir,
    detectors=("OF", "AFAR"),
    avatars=AVATARS,
    animations=ANIMATIONS,
):
    """Zero-lag cross-correlation for every video and detector.

    Parameters
    ----------
    data_dir : str or os.PathLike
        Directory holding the ``.mat`` files.
    detectors : sequence of str, optional
        Which detectors to compare against the ground truth.
    avatars, animations : sequence of str, optional
        Which videos to compare. Default to the full dataset.

    Returns
    -------
    pandas.DataFrame
        ``Avatar`` and ``Animation``, then one
        ``crosscorr_0_act-<detector>`` column per detector.

    Raises
    ------
    ValueError
        If any entry of ``detectors`` is not one of the compared tools.
    """
    for detector in detectors:
        _check_detector(detector)
    rows = []
    for avatar in avatars:
        for animation in animations:
            video = load_video(
                data_dir,
                avatar,
                animation,
                sources=("actual",) + tuple(detectors),
            )
            row = {"Avatar": avatar, "Animation": animation}
            for detector in detectors:
                row[f"crosscorr_0_act-{detector}"] = (
                    zero_lag_cross_correlation(
                        video["actual"], video[detector]
                    )
                )
            rows.append(row)
    return pd.DataFrame(rows)


def pairwise_landmark_correlations(
    derivatives_dir, avatars=AVATARS, animations=ANIMATIONS
):
    """Correlate the landmark motion of each avatar with every other.

    One row per ordered pair, so each unordered pair appears twice;
    :func:`drop_mirrored_pairs` reduces that to one row each.

    Parameters
    ----------
    derivatives_dir : str or os.PathLike
        Directory holding the landmark displacement files.
    avatars, animations : sequence of str, optional
        Which videos to compare. Default to the full dataset.

    Returns
    -------
    pandas.DataFrame
        ``Animation``, ``Avatar_0``, ``Avatar_1``, ``pearsonr`` and
        ``Pairs``, the last being the two avatar names joined.
    """
    rows = []
    for animation in animations:
        traces = {
            avatar: load_landmark_displacement(
                derivatives_dir, avatar, animation
            ).flatten()
            for avatar in avatars
        }
        for first in avatars:
            for second in avatars:
                if first == second:
                    continue
                rows.append(
                    {
                        "Animation": animation,
                        "Avatar_0": first,
                        "Avatar_1": second,
                        "pearsonr": float(
                            pearsonr(traces[first], traces[second])[0]
                        ),
                        "Pairs": f"{first}_{second}",
                    }
                )
    return pd.DataFrame(rows)


def drop_mirrored_pairs(table):
    """Keep one row of each unordered avatar pair per animation.

    Parameters
    ----------
    table : pandas.DataFrame
        As returned by :func:`pairwise_landmark_correlations`.

    Returns
    -------
    pandas.DataFrame
        The first row of each pair, re-indexed from zero.
    """
    seen = set()
    keep = []
    for row in table.itertuples():
        key = (row.Animation, frozenset((row.Avatar_0, row.Avatar_1)))
        if key in seen:
            continue
        seen.add(key)
        keep.append(row.Index)
    return table.loc[keep].reset_index(drop=True)


def active_inactive_ratio(displacement, target_indices):
    """Displacement of the targeted landmarks over that of the rest.

    The displacement is scaled by its own mean before the two groups are
    compared, which leaves the ratio unchanged but matches the published
    computation.

    Parameters
    ----------
    displacement : array_like
        Frames by landmarks, as
        :func:`au_detection_mh.utils.load_landmark_displacement`
        returns.
    target_indices : sequence of int
        Columns of ``displacement`` holding the landmarks the animation
        is expected to move.

    Returns
    -------
    float
        A percentage: 100 when both groups move equally far, above 100
        when the targeted landmarks move further.

    Raises
    ------
    ValueError
        If ``target_indices`` falls outside the landmarks, or names all
        of them, leaving nothing to compare against.
    """
    displacement = np.asarray(displacement, dtype=float)
    n_landmarks = displacement.shape[1]
    targets = np.asarray(target_indices, dtype=int)
    if targets.size and (targets.min() < 0 or targets.max() >= n_landmarks):
        raise ValueError(
            f"target_indices reach outside the {n_landmarks} landmarks "
            f"of the displacement array"
        )
    others = np.setdiff1d(np.arange(n_landmarks), targets)
    if others.size == 0:
        raise ValueError(
            "target_indices names every landmark, so there are no "
            "other landmarks to compare against"
        )
    scaled = displacement / displacement.mean()
    return float(scaled[:, targets].mean() / scaled[:, others].mean() * 100)
