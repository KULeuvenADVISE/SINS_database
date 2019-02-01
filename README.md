# SINS database
Author: Gert Dekkers (<gert.dekkers@kuleuven.be>, <https://iiw.kuleuven.be/onderzoek/advise/People/Gert_Dekkers>)

Introduction
===============
The SINS database consists of continuous recordings of one person living in a vacation home over a period of one week. It was collected using a network of 13 microphone arrays distributed over the entire home. Each microphone array consists of 4 linearly arranged microphones. This repository provides example code (MATLAB) to start with the data (i.e. segmentation, annotation and data exploration) along with the ground truth labels. Data is labelled on daily activity level (e.g. cooking, showering, presence, ...).

Getting started
===============
1. Read the paper regarding the [SINS database](https://www.cs.tut.fi/sgn/arg/dcase2017/documents/workshop_papers/DCASE2017Workshop_Dekkers_141.pdf),
2. Download the [needed data](#download),
3. Feel free to use the example code.

Download
==============

The data from each sensor node (id's matching the one on the [figure][other/2dplan.jpg]) is located in different repositories. The data for each sensor node is available at: [Node 1](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 2](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 3](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 4](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 6](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 7](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 8](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 9](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 10](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 11](https://zenodo.org/record/2546677#.XFR3DFVKhhE), [Node 12](https://zenodo.org/record/2546677#.XFR3DFVKhhE) and [Node 13](https://zenodo.org/record/2546677#.XFR3DFVKhhE)

**Note:** The downloads do not contain labels. These can be obtained at this GitHub repository in the `annotation` folder.

**Note:** Node 5 is not available because the node had issues (random crashes/missing data)

Repository overview
==============
    .
    ├── README.md				# (this) README file
    ├── example_code/				# Folder containing the example code
		├──── anno_reannotator.m	# Code for re-annotating or simply checking the data
		├──── anno_room_creator.m	# Create room specific-annotation from the original annotation
		├──── get_time_sync_info.m	# Get synchronization info needed by the segment_wav.m and anno_reannotator.m scripts
		├──── segment_wav.m		# Function to load the general parameters of the model
		├──── annotation/		# Folder containing the different parameter files
			└────── labels.csv	# CSV-file containing timestamps with labels
		└──── other/			# Sync related output files
    └── other/					# Folder containing other information which might be of interest


If you want more clarification on each script you can read the comments on top.

What's (not yet) in this database
==============
* sine sweeps (10s, 7 times) on multiple positions to obtain impulse responses. 
* Relative location of each sensor node

Changelog
=========
#### 1.0.0 / 2019-02-01

* First public release

License
=========

This software is released under the terms of the [MIT License](https://github.com/DCASE-REPO/dcase2018_baseline/blob/master/LICENSE).
This dataset is licensed under the license available in each Zenodo repository.
