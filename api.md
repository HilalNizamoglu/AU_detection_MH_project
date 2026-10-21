# API reference

The reference for `au_detection_mh` is generated from the docstrings in
the package with [pdoc](https://pdoc.dev/), and is served alongside this
book at [`api/au_detection_mh.html`](api/au_detection_mh.html).

Jupyter Book 2 does not generate API documentation from Python
docstrings, so the reference is produced separately and written into the
built site. `build_book.sh` runs both steps, and the book workflow runs
the same script.

| Module | Contents |
| --- | --- |
| `au_detection_mh.utils` | The avatar and animation names the dataset is indexed by, and the loaders that read the `.mat` and `.csv` files |
| `au_detection_mh.preprocessing` | Thresholding a prediction matrix against the rig ground truth, and the confusion counts that follow |
| `au_detection_mh.analyses` | The reported measures: classification metrics, zero-lag cross-correlation, pairwise landmark correlation, and the active-over-inactive displacement ratio |

The docstrings are written in
[numpydoc](https://numpydoc.readthedocs.io/en/latest/format.html) form,
with a `Parameters`, `Returns` and where relevant a `Raises` section, so
the reference states what each function accepts, what it returns and
which inputs it rejects.

Plotting and hypothesis testing are not in the package: the modules
return arrays, dictionaries and `pandas` objects, and the notebooks in
`analyses/` do the presentation and the statistics.
