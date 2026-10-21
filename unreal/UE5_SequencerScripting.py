"""Animate a MetaHuman face board and export the rig values it used.

Run this from the Unreal Engine 5 editor's Python console, not with
``uv run``: it imports the ``unreal`` module, which exists only inside
the editor process.  It does two things:

1. Assigns keys at the start, peak and end frame for every selected
   control rig, which is what animates the action unit.
2. Reads the resulting per-frame rig values back out, which is the
   ground truth the analyses in ``../analyses`` score the detectors
   against.

The controls to animate are whichever are selected in the editor when
the script runs; ``controlRigNames.txt`` lists the names of the
MetaHuman face board in the order the editor reports them.
"""

import os

import pandas as pd
import unreal

# Animation and MetaHuman names
MHS = ["Ada", "Garry"]
ANIMATIONS = [
    "AU01",
    "AU02",
    "AU04",
    "AU06",
    "AU07",
    "AU10",
    "AU12",
    "AU14",
    "AU15",
    "AU17",
    "AU23",
    "browsAll",
    "browsAU10",
    "browsAU12",
    "browsAU14",
    "browsAU15",
    "browsAU17",
    "browsAU23",
]

# The level sequence currently open in the editor, and its control rig
sequence_library = unreal.LevelSequenceEditorBlueprintLibrary
level_sequence = sequence_library.get_current_level_sequence()
rig_library = unreal.ControlRigSequencerLibrary
rig_proxies = rig_library.get_control_rigs(level_sequence)
rig = rig_proxies[0].control_rig

# The controls selected in the editor, for example
# "CTRL_L_mouth_cornerPull"
selected_controls = rig.current_control_selection()
print(selected_controls)
print(len(selected_controls))

# Frame range of the sequence, as integers
start_frame = level_sequence.get_playback_start()
print(start_frame)
end_frame = level_sequence.get_playback_end()
print(end_frame)
peak_frame = end_frame / 2

# Assign key values: zero at the start, full activation at the peak,
# back to zero at the end
for control in selected_controls:
    for frame, value in (
        (start_frame, 0),
        (peak_frame, 1),
        (end_frame, 0),
    ):
        rig_library.set_local_control_rig_float(
            level_sequence,
            rig,
            control,
            unreal.FrameNumber(frame),
            value,
            set_key=True,
        )

# Read the rig values back, one column per control
control_dict = {}
for control in selected_controls:
    rig_values = []
    for f in range(end_frame):
        value = rig_library.get_local_control_rig_float(
            level_sequence,
            rig,
            control,
            unreal.FrameNumber(f + 1),
        )
        rig_values.append(value)
    control_dict[control] = rig_values

print(control_dict)
df = pd.DataFrame(control_dict)
print(df)

# Set out_dir to where the exported rig values should be written.
# They become the ground truth the Python analyses read, after
# creating_AU_mat_files.m converts them to .mat.
out_dir = ""
df.to_csv(
    os.path.join(out_dir, f"{MHS[0]}_rigValues_anim_{ANIMATIONS[0]}.csv"),
    index=False,
)
