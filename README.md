# Mapping_skript_2.0

Script to map multiple SRA files with kallisto.

edit ProgPath.config to set your own paths

fasterq-dump: /usr/bin/fasterq-dump
kallisto: /usr/bin/kallisto


Test data is provided
just run the SRA_Multimapper.R Script

it should map 4 different experiments in single and paired end mode

create your own index for your species with kallisto index
insert your SRA runinfo file containing at least the colums
"Experiment" "Run" "LibraryLayout"

currently the SRA_RunInfo file is tab (\t) seperated
this might change in the future to comma (,) separated

edit the path to your SRA_Runinfo file and your index file
Experiment, Run, LibraryLayout
SRA_RunInfo<-"examples/SRA_minimal_example.txt"
generate an index with kallisto index
kallisto_index<-"examples/Solyc_example_index"

you can set the number of paralel_downloads. Do not exceed the number of cores you have available.
The more downloads are processed in parallel the more storage is required
paralel_downloads<-4


