# In this script, we would like to use UE5 LevelSequence and ControlRig functions to ...
#   1. Assign keys at certain frames for certain rigs
#   2. Retrieve true values of AUs per animation

import unreal
import numpy as np
import pandas as pd
import os

### ANIMATION AND METAHUMAN NAMES
MHs=['Ada','Garry']
animations=['AU01','AU02','AU04','AU06','AU07','AU10',
            'AU12','AU14','AU15','AU17','AU23','browsAll',
            'browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23']


### DEFINE "level_sequence" AND "rig"
level_sequence = unreal.LevelSequenceEditorBlueprintLibrary.get_current_level_sequence()
rig_proxies = unreal.ControlRigSequencerLibrary.get_control_rigs(level_sequence)
rig_proxy = rig_proxies[0]
rig = rig_proxy.control_rig

## DEFINE "rigControl"
selected_controls = rig.current_control_selection()
print(selected_controls)
print(len(selected_controls))
# or just a rigcontrol name such as: "CTRL_L_mouth_cornerPull"

### FRAMES
start_frame = level_sequence.get_playback_start() #returns integer
print(start_frame)
end_frame = level_sequence.get_playback_end() #returns integer
print(end_frame)
peak_frame = end_frame / 2

## ASSIGN KEY VALUES
# peak frame:
for control in range(len(selected_controls)):
    unreal.ControlRigSequencerLibrary.set_local_control_rig_float(level_sequence, rig, selected_controls[control], unreal.FrameNumber(start_frame), 0, set_key=True)
    unreal.ControlRigSequencerLibrary.set_local_control_rig_float(level_sequence, rig, selected_controls[control], unreal.FrameNumber(peak_frame), 1, set_key=True)
    unreal.ControlRigSequencerLibrary.set_local_control_rig_float(level_sequence, rig, selected_controls[control], unreal.FrameNumber(end_frame), 0, set_key=True)

## RETRIEVE FLOAT
control_dict={}
for control in range(len(selected_controls)):
    rig_values=[]
    for f in range(end_frame):
        frame=f+1
        value = unreal.ControlRigSequencerLibrary.get_local_control_rig_float(level_sequence, rig, selected_controls[control], unreal.FrameNumber(frame))
        rig_values.append(value)
    control_dict[selected_controls[control]] = rig_values

print(control_dict)    
df = pd.DataFrame(control_dict)
print(df)

df.to_csv(f'C:/Users/hilal/Desktop/JLU-Dobs/{MHs[0]}_rigValues_anim_{animations[0]}.csv', index=False)  