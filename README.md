# AU_detection_MH_project
Creating MH animations on UE5 to test AU Detection Tools 

Here you will find ...
- script to manipulate UE5 Sequencer Scene and Level to create MetaHuman animations:
AU_detection_MH_project/Python Notebooks and Functions/UE5_SequencerScripting.py

- code to run AFARtoolbox:
AU_detection_MH_project/MATLAB Scripts/run_afar_v1.m

- scripts to analyze AU detection tools' outputs: 
AU_detection_MH_project/MATLAB Scripts/OpenFace_output_script.m
AU_detection_MH_project/MATLAB Scripts/OFvsAFAR_output_and_plot.m
AU_detection_MH_project/MATLAB Scripts/AFAR_output_script.m
AU_detection_MH_project/MATLAB Scripts/creating_AU_mat_files.m

- main analysis scripts: 
Running Landmark Displacement Analysis:
AU_detection_MH_project/MATLAB Scripts/rigid_inverse_affine_transformation.m

Running Analysis for Spatial Correspondence with Expected Motion
AU_detection_MH_project/MATLAB Scripts/active_vs_inactive_landm_ratio.m

- main analysis jupyter-notebook walkthrough: 
analyses_and_figures_no-posthocs_script.ipynb

- Required libraries and Python Version:
Python version = 3.10.12
jupyter==1.0.0
ipykernel==6.29.0
jupyter-book==0.15.1
matplotlib==3.8.2
plotly==5.18.0
seaborn==0.11.0
numpy==1.26.3
scipy==1.12.0
pandas==2.2.0
scikit-learn==1.4.0
pingouin==0.5.4
statsmodels==0.14.1


