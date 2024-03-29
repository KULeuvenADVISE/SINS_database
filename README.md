Note: a python port is available at https://github.com/fgnt/sins. We thank the authors for their contribution!

# SINS database
Authors: Gert Dekkers (<gert.dekkers@kuleuven.be>, <https://iiw.kuleuven.be/onderzoek/advise/People/Gert_Dekkers>), Steven Lauwereins, Bart Thoen, Mulu Weldegebreal Adhana, Henk Brouckxon, Bertold Van den Bergh, Toon van Waterschoot, Bart Vanrumste, Marian Verhelst and Peter Karsmakers.
KU Leuven/Vrije Universiteit Brussel

Introduction
===============
The SINS database consists of continuous audio recordings of one person living in a vacation home over a period of one week. It was collected using a network of 13 microphone arrays distributed over the multiple rooms. Each microphone array consisted of 4 linearly arranged microphones. This repository provides example code (MATLAB) to start with the data (i.e. segmentation, annotation and data exploration) along with the ground truth labels. Data is labeled on daily activity level (e.g. cooking, showering, presence, ...).

This dataset served as a base for the [DCASE 2018 Challenge Task 5](http://dcase.community/challenge2018/task-monitoring-domestic-activities).

Getting started
===============
1. Read the paper regarding the [SINS database](https://www.cs.tut.fi/sgn/arg/dcase2017/documents/workshop_papers/DCASE2017Workshop_Dekkers_141.pdf),
2. Download the [needed data](#download),
3. Feel free to use the example code.

Download
==============

The data from each sensor node (id's matching the one on the [figure](other/2dplan.jpg) and [paper](https://www.cs.tut.fi/sgn/arg/dcase2017/documents/workshop_papers/DCASE2017Workshop_Dekkers_141.pdf)) is located in different repositories. The data for each sensor node is available at: [Node 1](https://zenodo.org/record/2546677#.XFR-KlVKhhE), [Node 2](https://zenodo.org/record/2547307#.XFR-RFVKiUk), [Node 3](https://zenodo.org/record/2547309#.XFR-V1VKiUk), [Node 4](https://zenodo.org/record/2555084#.XFR-d1VKiUk), [Node 6](https://zenodo.org/record/2547313#.XFR-jFVKiUk), [Node 7](https://zenodo.org/record/2547315#.XFR-sFVKiUk), [Node 8](https://zenodo.org/record/2547319#.XFR-8FVKiUk), [Node 9](https://zenodo.org/record/2555080#.XFR_GlVKiUk), [Node 10](https://zenodo.org/record/2555137#.XFR_QFVKiUk), [Node 11](https://zenodo.org/record/2555139#.XFR_XFVKiUk), [Node 12](https://zenodo.org/record/2555141#.XFR_f1VKiUk) and [Node 13](https://zenodo.org/record/2555143#.XFR_nVVKiUk)

**Note:** The downloads do not contain labels. These can be obtained at this GitHub repository in the `annotation` folder.

**Note:** Node 5 is not available because the node had issues (random crashes/missing data)

Data repository overview
==============

    ├── readme.md			# readme file
    ├── license.pdf			# license file
	    └── audio/			# Folder containing the data
		├──── Node1/		# Folder containing the data for a particular node
		├──── ...
		└──── Node13/		# Folder containing the data for a particular node
			├──── audio/ 	# folder containing audio files
				└──── Node13_YYYYMMDD_HHMMSS_FFF_audio.wav
			└──── sync/	# folder containing sync files
				└──── Node13_YYYYMMDD_HHMMSS_FFF_sync.mat

Each Zenodo repository contains the data for a particular sensor node. This includes .wav files (`audio/NodeX/audio` folder of ~60s where each file has the starting point in time in its filename (format: Y= year, M=month, D=day, H=hour, M=minutes, S=seconds, F=milliseconds). This timestamp was acquired by the current time of the raspberrypi when saving.

Besides audio we also provided so-called sync files for each wave file. The microcontroller responsible for the sampling of the audio also had an internal counter value that we saved. This value is incremented by a clock of 48kHz. A reference signal was connected to each microcontroller and caused an interrupt on the microcontroller to reset its internal counter value every second. The signal itself was generated by an accurate clock.  Each digitized audio sample was send through along with the counter value. So each second all the sync clocks reset. If you assume no clock drift during one second then you could use this information to select samples accross sensor nodes. The microphones in a single sensor node are synchronized, but accross sensor nodes there is a mismatch. These sync files can help to acquire a rough synchronization (+- 0.5s). The example code for segmenting and annotating also exploites these sync pulses.

GitHub Repository overview
==============
    .
    ├── README.md				# (this) README file
    ├── example_code/			# Folder containing the example code
		├──── anno_reannotator.m	# Code for re-annotating or simply checking the data
		├──── anno_room_creator.m	# Create room specific-annotation from the original annotation
		├──── get_time_sync_info.m	# Get synchronization info needed by the segment_wav.m and anno_reannotator.m scripts
		├──── segment_wav.m		# Function to load the general parameters of the model
    ├── annotation/				# Folder containing the different parameter files
	└────── labels.csv			# CSV-file containing timestamps with labels
		└──── other/			# Sync related output files
    └── other/				# Folder containing other information which might be of interest

The folder `example_code` contains code for segmenting (`segment_wav.m`), (re-)annotating (`anno_reannotator.m`) and creating room specific labels (`anno_room_creator.m`). The main label file is `annotation/labels.csv`, while the others are derivatives given a particular room obtained by `anno_room_creator.m`. `get_time_sync_info.m` contains code to acquire sync-related data (used by the segmenting and annotation code) from the sync files available in the data repository. Everything is already processed and output files are available in `annotation/other`, so these are available for your information.

If you want more clarification on each script you can read the comments on top.

Changelog
=========
#### 1.0.0 / 2019-02-01

* First public release

License
=========

This software is released under the terms of the [MIT License](https://github.com/DCASE-REPO/dcase2018_baseline/blob/master/LICENSE).
This dataset is licensed under the license available in each Zenodo repository.

When using this database you should cite the following paper:

Gert Dekkers, Steven Lauwereins, Bart Thoen, Mulu Weldegebreal Adhana, Henk Brouckxon, Toon van Waterschoot, Bart Vanrumste, Marian Verhelst, and Peter Karsmakers, The SINS database for detection of daily activities in a home environment using an acoustic sensor network, Proceedings of the Detection and Classification of -Acoustic Scenes and Events 2017 Workshop (DCASE2017), pp 32–36, November 2017.
