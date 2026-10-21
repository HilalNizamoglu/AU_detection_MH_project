# Derivatives

Output the analyses produce from the data in the parent directory, one
subdirectory per processing step or pipeline, each with its own
`dataset_description.json` naming what generated it and at which
version.

| Subdirectory | Produced by | Contents |
| --- | --- | --- |
| `landmark-displacement/` | `matlab/rigid_inverse_affine_transformation.m` | `<avatar>_<animation>_landmark_displacement.csv`, one row per frame and one column per landmark, after head motion has been removed by the rigid inverse affine transform |
| `au-detection-metrics/` | the notebooks in `analyses/`, via `au_detection_mh` | The group-level tables behind the figures: per-detector classification metrics, zero-lag cross-correlations, and the active-over-inactive landmark displacement ratios |

What belongs in version control here is covered by the two questions in
[the dataset README](../README.md): per-frame output large enough to
push a file over 50 MiB belongs in an archive alongside the videos,
while group-level results, model outputs, scores and the numbers behind
the figures are small enough to commit, once they have been checked for
identifying information.
