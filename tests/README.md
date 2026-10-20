# Tests

Tests for the `AU_detection_MH_project` are located here. These `tests`
are designed to ensure the `correctness` and `reliability` of the
various `components` of the `project`.

| File | Covers |
| --- | --- |
| `test_installation.py` | That `au_detection_mh` and each of its modules import from the environment `uv sync` creates |
| `test_utils.py` | The avatar and animation constants, the filename convention, and the loaders |
| `test_preprocessing.py` | Thresholding and the confusion counts |
| `test_analyses.py` | The classification metrics, cross-correlation, pairwise landmark correlation and displacement ratio |

Run them with:

```bash
uv run pytest
```

The tests build their inputs in `tmp_path` fixtures rather than reading
`../ds-au_detection_mh`, so they pass in a checkout where the dataset
has not been retrieved.
