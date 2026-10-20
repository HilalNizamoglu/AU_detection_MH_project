# MATLAB analyses

MATLAB sources that produced the data in
[`../ds-au_detection_mh`](../ds-au_detection_mh). They are not part of
the `au_detection_mh` package and are not run by the container images,
which carry no MATLAB; they are kept here so the record of how the data
was produced travels with the repository.

| Script | Step |
| --- | --- |
| `run_afar_v1.m` | Runs the AFAR toolbox over a directory of rendered animation videos |
| `OpenFace_output_script.m` | Reads the OpenFace `.csv` output and assembles the AU intensity matrices |
| `AFAR_output_script.m` | The same for the AFAR output |
| `OFvsAFAR_output_and_plot.m` | Compares the two detectors and plots the result |
| `creating_AU_mat_files.m` | Writes the `sourcedata/*_{actualValues,OFpred,AFARpred,PYFEATpred}_anim_*.mat` files the Python analyses read |
| `rigid_inverse_affine_transformation.m` | Removes head motion from the OpenFace landmark traces and writes `derivatives/landmark-displacement/` |
| `active_vs_inactive_landm_ratio.m` | Mean displacement of the landmarks an animation targets over the mean of the rest |

## Prerequisites

These are external to this repository and have to be installed
separately:

- MATLAB. The published run used R2021b or later with the Image
  Processing and Statistics and Machine Learning toolboxes; record the
  exact version here once confirmed.
- [OpenFace](https://github.com/TadasBaltrusaitis/OpenFace), for the AU
  intensities and the 2D landmarks.
- [AFARtoolbox](https://github.com/AffectAnalysisGroup/AFARtoolbox).
  `run_afar_v1.m` was written against the `mesh_visualization` branch
  and, on Windows, needs the Visual Studio 2015 redistributable noted in
  its header.
- [py-feat](https://py-feat.org/), which produced the `PYFEATpred`
  matrices from Python rather than from MATLAB.

Record the version of each tool in
`../ds-au_detection_mh/dataset_description.json` under `GeneratedBy`,
since the detector version is what the comparison is about.

## Paths

Each script begins with the path it reads from. Those paths were
absolute paths on the machine the analyses were run on and have been
replaced with a `data_root` variable, set near the top of the file, that
defaults to `../ds-au_detection_mh`. Set it to wherever the rendered
videos are when re-running a step that needs them, since the videos are
not in this repository.

`active_vs_inactive_landm_ratio.m` loads a `motion_params.mat` that is
not committed: it is the per-video landmark displacement struct that
`rigid_inverse_affine_transformation.m` produces, and the committed
`derivatives/landmark-displacement/*.csv` files are the same numbers in
CSV form. Re-run the transform to regenerate it.
