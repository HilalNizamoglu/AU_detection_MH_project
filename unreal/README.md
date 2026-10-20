# Unreal Engine stimulus generation

Scripts that run inside the Unreal Engine 5 Python interpreter to build
the MetaHuman animations the detectors were evaluated on. They are not
importable by the analyses and are not run by the container images,
which carry no Unreal Engine.

| File | Contents |
| --- | --- |
| `UE5_SequencerScripting.py` | Drives the Sequencer to set each control rig value over the animation, render the sequence, and export the rig values that become the ground truth |
| `controlRigNames.txt` | The control rig curve names of the MetaHuman face board, in the order the script indexes them |

## Prerequisites

- Unreal Engine 5 with the Python Editor Script Plugin enabled. Record
  the exact engine version here, since the MetaHuman face board changed
  between releases and the names in `controlRigNames.txt` follow one
  version of it.
- The four MetaHuman presets `Ada`, `Garry`, `Cooper` and `Pia`,
  downloaded through Quixel Bridge into the project.

## Running

`UE5_SequencerScripting.py` is executed from the editor's Python
console, not with `uv run`: it imports the `unreal` module, which only
exists inside the editor process. Set the output path at the end of the
script to where the rig values should be written before running it.

The rendered videos are not in this repository. They are the input to
the detectors in [`../matlab`](../matlab), and are reproducible from
this script plus the MetaHuman assets.
