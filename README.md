# Mapping_skript_2.0

Script to map multiple SRA files with kallisto.

Edit ProgPath.config to set your own paths:

fasterq-dump: /usr/bin/fasterq-dump

kallisto: /usr/bin/kallisto

# Test your installation and configuration
Test data is provided.
Just run the SRA_Multimapper.R Script

It should map 4 different experiments in single and paired end mode.


# How to start the download and the mapping
Create your own index for your species with kallisto index.
Insert your SRA runinfo file containing at least the colums:
"Experiment" "Run" "LibraryLayout"

Currently the SRA_RunInfo file is tab (\t) seperated.
This might change in the future to comma (,) separated.

Edit the path to your SRA_Runinfo file and your index file.
Experiment, Run, LibraryLayout
SRA_RunInfo<-"examples/SRA_minimal_example.txt"
generate an index with kallisto index
kallisto_index<-"examples/Solyc_example_index"

You can set the number of paralel_downloads. Do not exceed the number of cores you have available.
The more downloads are processed in parallel the more storage is required.
paralel_downloads<-4

