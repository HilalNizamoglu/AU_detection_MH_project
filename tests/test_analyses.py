"""Tests for the reported measures in au_detection_mh.analyses.

The confusion worked example is the one documented in
``test_preprocessing``: one cell in each of the four categories, which
puts every rate at 0.5.
"""

import numpy as np
import pandas as pd
import pytest
from scipy.io import savemat
from scipy.stats import pearsonr

from au_detection_mh import analyses, utils

THRESHOLD = 0.2
ACTUAL = np.array([[0.5, 0.0], [0.0, 0.3]])
PREDICTED = np.array([[0.9, 0.8], [0.1, 0.1]])
LABELS = ("AU01", "AU02")


@pytest.fixture
def sourcedata(tmp_path):
    """Two avatars and one animation, each source a distinct matrix."""
    directory = tmp_path / "sourcedata"
    directory.mkdir()
    for avatar in ("Ada", "Garry"):
        for source, (infix, variable) in utils.MAT_SOURCES.items():
            matrix = ACTUAL if source == "actual" else PREDICTED
            savemat(
                directory / f"{avatar}_{infix}_anim_AU01.mat",
                {variable: matrix},
            )
    return directory


@pytest.fixture
def displacements(tmp_path):
    """Landmark displacement for three avatars and one animation.

    ``Ada`` and ``Garry`` are identical, so their correlation is 1;
    ``Cooper`` is the reverse, so it correlates negatively with both.
    """
    directory = tmp_path / "landmark-displacement"
    directory.mkdir()
    rows = {
        "Ada": "1,2,3\n4,5,6\n",
        "Garry": "1,2,3\n4,5,6\n",
        "Cooper": "6,5,4\n3,2,1\n",
    }
    for avatar, text in rows.items():
        path = directory / utils.landmark_filename(avatar, "AU01")
        path.write_text(text)
    return directory


def test_sensitivity_is_true_positives_over_actual_positives():
    assert analyses.sensitivity(1, 1) == 0.5
    assert analyses.sensitivity(3, 1) == 0.75


def test_false_positive_rate_is_false_positives_over_negatives():
    assert analyses.false_positive_rate(1, 1) == 0.5
    assert analyses.false_positive_rate(1, 3) == 0.25


def test_specificity_is_true_negatives_over_negatives():
    assert analyses.specificity(1, 1) == 0.5
    assert analyses.specificity(3, 1) == 0.75


def test_precision_is_true_positives_over_predicted_positives():
    assert analyses.precision(1, 1) == 0.5
    assert analyses.precision(1, 3) == 0.25


@pytest.mark.parametrize(
    "function",
    [
        analyses.sensitivity,
        analyses.false_positive_rate,
        analyses.specificity,
        analyses.precision,
    ],
)
def test_rates_warn_and_return_none_on_an_empty_denominator(function):
    """A rate with nothing to divide by is undefined, and says so."""
    with pytest.warns(UserWarning):
        assert function(0, 0) is None


def test_f1_score_is_the_harmonic_mean():
    assert analyses.f1_score(0.5, 0.5) == 0.5
    assert analyses.f1_score(1.0, 0.5) == pytest.approx(2 / 3)


def test_f1_score_warns_and_returns_zero_when_a_rate_is_undefined():
    """An undefined precision leaves no F1 to report."""
    with pytest.warns(UserWarning):
        assert analyses.f1_score(0.5, None) == 0.0
    with pytest.warns(UserWarning):
        assert analyses.f1_score(None, 0.5) == 0.0


def test_f1_score_warns_and_returns_zero_when_both_rates_are_zero():
    """Neither sensitivity nor precision leaves nothing to average."""
    with pytest.warns(UserWarning):
        assert analyses.f1_score(0.0, 0.0) == 0.0


def test_roc_auc_is_one_for_a_perfectly_separable_prediction():
    actual = np.array([[0.9, 0.0], [0.9, 0.0]])
    predicted = np.array([[0.8, 0.1], [0.7, 0.2]])
    assert analyses.roc_auc(actual, predicted, THRESHOLD) == 1.0


def test_roc_auc_scores_the_worked_example():
    """Three of four positive-negative pairs ordered, one tied."""
    assert analyses.roc_auc(
        ACTUAL, PREDICTED, THRESHOLD
    ) == pytest.approx(0.625)


def test_roc_auc_thresholds_only_the_ground_truth():
    """The prediction enters as a score, not as a binary label."""
    actual = np.array([[0.9, 0.0]])
    coarse = analyses.roc_auc(actual, np.array([[1.0, 0.0]]), THRESHOLD)
    fine = analyses.roc_auc(actual, np.array([[0.3, 0.25]]), THRESHOLD)
    assert coarse == fine == 1.0


def test_classification_metrics_carries_counts_rates_and_auc():
    """One row of the published table, for one avatar and animation."""
    row = analyses.classification_metrics(
        ACTUAL, PREDICTED, THRESHOLD, labels=LABELS
    )
    assert row["TP"] == 1
    assert row["FP"] == 1
    assert row["TN"] == 1
    assert row["FN"] == 1
    assert row["false_detections"] == ["AU02"]
    assert row["TP_perc"] == 25
    assert row["TPR"] == 0.5
    assert row["FPR"] == 0.5
    assert row["F1_score"] == 0.5
    assert row["AUC"] == pytest.approx(0.625)


def test_classification_metrics_labels_columns_by_au_animation():
    """Without explicit labels, columns are the 11 single-AU names."""
    actual = np.zeros((2, 11))
    predicted = np.zeros((2, 11))
    predicted[0, 3] = 0.9
    row = analyses.classification_metrics(actual, predicted, THRESHOLD)
    assert row["false_detections"] == [utils.AU_ONLY_ANIMATIONS[3]]


def test_classification_metrics_table_has_a_row_per_video(sourcedata):
    """One row per avatar and animation, named in the first columns."""
    table = analyses.classification_metrics_table(
        sourcedata,
        "OF",
        THRESHOLD,
        avatars=("Ada", "Garry"),
        animations=("AU01",),
        labels=LABELS,
    )
    assert isinstance(table, pd.DataFrame)
    assert len(table) == 2
    assert list(table.columns[:2]) == ["avatar", "animation"]
    assert list(table["avatar"]) == ["Ada", "Garry"]
    assert set(table["animation"]) == {"AU01"}
    assert table["AUC"].iloc[0] == pytest.approx(0.625)


def test_classification_metrics_table_rejects_an_unknown_detector(
    sourcedata,
):
    """The ground truth is not a detector to be scored against itself."""
    with pytest.raises(ValueError, match="actual"):
        analyses.classification_metrics_table(
            sourcedata,
            "actual",
            THRESHOLD,
            avatars=("Ada",),
            animations=("AU01",),
        )


def test_zero_lag_cross_correlation_of_a_signal_with_itself_is_one():
    signal = np.array([0.0, 1.0, 2.0, 1.0, 0.0])
    assert analyses.zero_lag_cross_correlation(
        signal, signal
    ) == pytest.approx(1.0)


def test_zero_lag_cross_correlation_matches_pearson_r():
    """For equal-length signals the lag-0 value is Pearson's r."""
    rng = np.random.default_rng(0)
    a = rng.normal(size=40)
    b = rng.normal(size=40)
    assert analyses.zero_lag_cross_correlation(a, b) == pytest.approx(
        pearsonr(a, b)[0]
    )


def test_zero_lag_cross_correlation_flattens_a_matrix():
    """A frames-by-AUs matrix is compared as one concatenated trace."""
    matrix = np.arange(12, dtype=float).reshape(4, 3)
    assert analyses.zero_lag_cross_correlation(
        matrix, matrix
    ) == pytest.approx(1.0)


def test_zero_lag_cross_correlation_is_negative_for_an_inverted_signal():
    signal = np.array([0.0, 1.0, 2.0, 3.0])
    assert analyses.zero_lag_cross_correlation(
        signal, -signal
    ) == pytest.approx(-1.0)


def test_cross_correlation_profile_is_restricted_to_the_max_lag():
    """The profile spans plus and minus max_lag, and contains lag 0."""
    signal = np.arange(20, dtype=float)
    lags, correlation = analyses.cross_correlation_profile(
        signal, signal, max_lag=5
    )
    assert lags.min() == -5
    assert lags.max() == 5
    assert len(lags) == len(correlation) == 11
    assert correlation[lags == 0][0] == pytest.approx(1.0)


def test_cross_correlation_profile_defaults_to_a_quarter_of_the_trace():
    """The published run restricted the lags to a quarter of the length."""
    signal = np.arange(20, dtype=float)
    lags, _ = analyses.cross_correlation_profile(signal, signal)
    assert lags.max() == 20 // 4


def test_cross_correlation_table_has_a_column_per_detector(sourcedata):
    """One row per video, one cross-correlation column per detector."""
    table = analyses.cross_correlation_table(
        sourcedata,
        detectors=("OF", "AFAR"),
        avatars=("Ada", "Garry"),
        animations=("AU01",),
    )
    assert len(table) == 2
    assert list(table.columns) == [
        "Avatar",
        "Animation",
        "crosscorr_0_act-OF",
        "crosscorr_0_act-AFAR",
    ]
    expected = analyses.zero_lag_cross_correlation(ACTUAL, PREDICTED)
    assert table["crosscorr_0_act-OF"].iloc[0] == pytest.approx(expected)


def test_pairwise_landmark_correlations_covers_ordered_pairs(
    displacements,
):
    """Every avatar against every other, both ways round."""
    table = analyses.pairwise_landmark_correlations(
        displacements,
        avatars=("Ada", "Garry", "Cooper"),
        animations=("AU01",),
    )
    assert len(table) == 6
    assert list(table.columns) == [
        "Animation",
        "Avatar_0",
        "Avatar_1",
        "pearsonr",
        "Pairs",
    ]
    assert not (table["Avatar_0"] == table["Avatar_1"]).any()


def test_pairwise_landmark_correlations_computes_pearson_r(
    displacements,
):
    """Identical traces correlate at 1, reversed ones at -1."""
    table = analyses.pairwise_landmark_correlations(
        displacements,
        avatars=("Ada", "Garry", "Cooper"),
        animations=("AU01",),
    )
    indexed = table.set_index("Pairs")["pearsonr"]
    assert indexed["Ada_Garry"] == pytest.approx(1.0)
    assert indexed["Ada_Cooper"] == pytest.approx(-1.0)


def test_drop_mirrored_pairs_keeps_one_of_each_unordered_pair(
    displacements,
):
    """Three avatars give three unordered pairs, not six ordered ones."""
    table = analyses.pairwise_landmark_correlations(
        displacements,
        avatars=("Ada", "Garry", "Cooper"),
        animations=("AU01",),
    )
    unique = analyses.drop_mirrored_pairs(table)
    assert len(unique) == 3
    seen = {
        frozenset((row.Avatar_0, row.Avatar_1))
        for row in unique.itertuples()
    }
    assert len(seen) == 3


def test_active_inactive_ratio_compares_targeted_to_other_landmarks():
    """Targeted landmarks moving a third as far gives 33 percent."""
    displacement = np.array([[1.0, 1.0], [3.0, 3.0]])
    ratio = analyses.active_inactive_ratio(displacement, [0])
    assert ratio == pytest.approx(100 / 3)


def test_active_inactive_ratio_is_one_hundred_when_motion_is_uniform():
    """No preference for the targeted landmarks is 100 percent."""
    displacement = np.array([[2.0, 2.0], [2.0, 2.0]])
    assert analyses.active_inactive_ratio(
        displacement, [0]
    ) == pytest.approx(100.0)


def test_active_inactive_ratio_is_scale_invariant():
    """Scaling every landmark leaves the ratio unchanged."""
    displacement = np.array([[1.0, 1.0], [3.0, 3.0]])
    assert analyses.active_inactive_ratio(
        displacement * 7.0, [0]
    ) == pytest.approx(analyses.active_inactive_ratio(displacement, [0]))


def test_active_inactive_ratio_rejects_targeting_every_landmark():
    """With no landmarks left over there is nothing to compare against."""
    displacement = np.array([[1.0, 1.0], [3.0, 3.0]])
    with pytest.raises(ValueError, match="landmark"):
        analyses.active_inactive_ratio(displacement, [0, 1])


def test_active_inactive_ratio_rejects_an_out_of_range_index():
    """A target index past the last landmark is an error."""
    displacement = np.array([[1.0, 1.0], [3.0, 3.0]])
    with pytest.raises(ValueError, match="landmark"):
        analyses.active_inactive_ratio(displacement, [5])
