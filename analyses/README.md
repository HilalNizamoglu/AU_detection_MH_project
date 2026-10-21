# Analyses documentation

This directory contains the `documentation` for the analyses of the
`AU_detection_MH_project`. Each notebook covers one step, imports the
code it needs from [`au_detection_mh`](../au_detection_mh), and reads
and writes the dataset in [`../ds-au_detection_mh`](../ds-au_detection_mh).

| Notebook | Step |
| --- | --- |
| `01_classification_metrics.ipynb` | Thresholds each detector's predictions against the rig ground truth and writes the per-avatar, per-animation classification metrics to `derivatives/au-detection-metrics/` |
| `02_binary_classification_performance.ipynb` | AUC against chance, between-detector and within-factor comparisons, and the AUC/TPR/FPR panels of Figure 2 |
| `03_temporal_alignment.ipynb` | Zero-lag cross-correlation between the rig ground truth and each detector, and Figure 3 |
| `04_landmark_displacement.ipynb` | Consistency of landmark displacement across avatars, and the spatial correspondence of displacement with the AU each animation targets |

Run them in that order: `01` writes the tables the other three read.

They are committed with the outputs of a full run, so the tables and
figures are readable without executing anything. To run them, install
the extra that carries Jupyter, `matplotlib`, `seaborn` and `pingouin`:

```bash
uv sync --extra notebooks
uv run jupyter lab
```

Each notebook also writes its figures as `.svg` next to the tables in
`../ds-au_detection_mh/derivatives/au-detection-metrics/`. Those files
are not committed, so a run leaves them untracked.

`analyses_and_figures_no-posthocs_script.ipynb` is the original
single-notebook walkthrough the four above were derived from, kept for
reference with its executed output intact.
