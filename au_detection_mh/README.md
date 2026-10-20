# Analyses code

This directory contains the `code` for the analyses of the
`AU_detection_MH_project`, installed as the `au_detection_mh` package
and imported by the notebooks in [`../analyzes`](../analyzes).

| Module | Contents |
| --- | --- |
| `utils.py` | The avatar and animation names the dataset is indexed by, and the loaders that read the `.mat` and `.csv` files in `../ds-au_detection_mh` |
| `preprocessing.py` | Thresholding a prediction matrix against the rig ground truth, and the confusion counts that follow from it |
| `analyses.py` | The reported measures: classification metrics per avatar and animation, zero-lag cross-correlation, pairwise landmark correlation, and the active-over-inactive displacement ratio |

Each module returns arrays, dictionaries or `pandas` objects. Plotting
and hypothesis testing stay in the notebooks, which is why `matplotlib`,
`seaborn` and `pingouin` are in the `notebooks` extra rather than in
`dependencies`.

The MATLAB and Unreal Engine sources that produced the data these
modules read are in [`../matlab`](../matlab) and
[`../unreal`](../unreal).
