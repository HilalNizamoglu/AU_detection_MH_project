# AU_detection_MH_project - Data

This directory holds the dataset for the `AU_detection_MH_project`,
following the
[BIDS](https://bids-standard.github.io/bids-starter-kit/) layout as far
as it applies: `dataset_description.json` describes the dataset,
`sourcedata/` holds what the analyses start from, and `derivatives/`
holds what they produce from it.

The units of this dataset are four
[MetaHuman](https://www.unrealengine.com/en-US/metahuman) avatars
(`Ada`, `Garry`, `Cooper`, `Pia`) crossed with 18 animations (11
single-AU animations and 7 brow combinations), giving 72 animated
videos. There is no participant level, so there are no `sub-*`
directories and no `participants.tsv`.

## Layout

| Path | Contents |
| --- | --- |
| `sourcedata/<avatar>_actualValues_anim_<animation>.mat` | Rig activation values read back from the Unreal Engine 5 sequence, used as the ground truth |
| `sourcedata/<avatar>_OFpred_anim_<animation>.mat` | OpenFace AU intensities, normalised to the rig scale |
| `sourcedata/<avatar>_AFARpred_anim_<animation>.mat` | AFAR toolbox AU occurrence predictions |
| `sourcedata/<avatar>_PYFEATpred_anim_<animation>.mat` | py-feat AU predictions |
| `sourcedata/AU_landm_mapping.mat` | Which facial landmarks each animation is expected to move, read by `matlab/active_vs_inactive_landm_ratio.m` |
| `derivatives/landmark-displacement/` | Per-frame landmark displacement after the rigid inverse affine transform |
| `derivatives/au-detection-metrics/` | Group-level classification metrics, cross-correlations and landmark ratios behind the figures |

Each `.mat` file holds one matrix of frames by AUs, under the variable
name the loader in `au_detection_mh.utils` expects. The rendered videos
the three detectors were run on are not in this repository; they are
reproducible from `unreal/UE5_SequencerScripting.py` and the MetaHuman
assets, and `matlab/README.md` records the detector versions.

Whether a given file belongs here in version control depends on two
questions, and a file has to pass both. The first is about size, the
second about what the file contains. A behavioural table or a
questionnaire export passes the size question easily and is one of the
likeliest places to fail the second.

## 1. Is it small enough for git?

GitHub warns above 50 MiB per file and **refuses** a push containing a
file over 100 MiB, and recommends keeping a whole repository under 1 GB.
That makes the division roughly:

**Keep out of git:**

- the rendered animation videos, and any raw detector output kept per
  frame and per landmark rather than summarised
- anything else that would put a single file over 50 MiB, or the
  directory into the hundreds of MB

**Reasonable to commit:**

- `dataset_description.json` and the other sidecars and metadata
- the rig ground truth and the detector predictions, which are a few
  tens of KB each
- model outputs, fitted parameters and scores
- group-level and summary derivatives, and the numbers behind the
  figures in the paper

Everything currently committed here is in the second group and comes to
roughly 5 MB.

Data kept out of git belongs in an archive that issues a persistent
identifier — OpenNeuro, or a Zenodo or OSF deposit. Record the accession
or DOI in `dataset_description.json` under `DatasetDOI` and
`SourceDatasets`, and describe how to retrieve it below, so the
repository stays the place someone starts from.

### DataLad

[DataLad](https://www.datalad.org/) is supported for the files kept
outside git, and is not required. This dataset does not currently use
it: everything that is published is committed directly, and the
rendered videos are regenerated rather than retrieved. Should the videos
or any other large file be deposited later, this section is where the
accession and the retrieval command belong.

## 2. Does it contain identifying information?

Check before committing anything, not afterwards: a push is public and
removing a file in a later commit leaves it in the history. At minimum,
look for

- dates of birth, scan dates, and dates of other personal events
- names in values, in column headers, in filenames and in file paths
- free-text fields, which are excluded unless there is a specific
  decision to include them
- health and medical information
- data describing people who are not participants, such as relatives,
  which is likewise excluded unless specifically decided otherwise

and look beyond the top-level columns of a table, because the same
information travels in places a flat key scan does not reach: nested
JSON objects inside sidecars, gzip and NIfTI headers, embedded tags in
audio and video, and per-volume or per-trial metadata. Sidecars repay
the attention in particular — a single template field that carries a
name reproduces into every sidecar in the dataset, which is a pattern
that has shown up in a public dataset used here.

Two carriers matter for this dataset specifically. The `.mat` headers
record the date and platform the file was written on, which is a file
timestamp rather than a personal date. And the avatar names in every
filename are Unreal Engine MetaHuman presets rather than people, which
is worth stating in a data statement so that a reader does not mistake
them for participants.

When something turns up, report where it is rather than copying the
values into an issue, a commit message or a working file, and decide how
to handle it before it reaches a commit.
