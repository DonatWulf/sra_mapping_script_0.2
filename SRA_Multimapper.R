library(tidyverse)
#library(tidyverse, lib.loc = "/mnt/data/R/library/")
library(doParallel)
library(reticulate)

source_python("kallisto_mapping_multiple.py")

##### read config file ######
config_<-read_delim("ProgPath.config",delim=": ",col_names=F)%>%
  mutate(X2=str_remove_all(X2," *"))
fasterq_dump_path<-config_%>%
  filter(X1=="fasterq-dump")%>%
  pull(X2)
kallisto_path<-config_%>%
  filter(X1=="kallisto")%>%
  pull(X2)


##### index and SRA RunInfo file #####
#needed columnnames RunInfo file
# Experiment, Run, LibraryLayout
SRA_RunInfo<-"examples/SRA_minimal_example.txt"
# generate an index with kallisto index
kallisto_index<-"examples/Solyc_example_index"


##### read SRA RunInfo file #####
df<-read_csv(SRA_RunInfo, guess_max = 22000)


colnames(df)


##### filter already mapped experiments #####
already_mapped<-c("")
#get mapped experiments from foldernames
already_mapped<-list.files(pattern="abundance.tsv",recursive = T)%>%
  enframe(value="filenames")%>%
  mutate(filenames=str_remove(filenames,"_out.*"))%>%
  pull(filenames)%>%
  c(already_mapped)


# filter
df<-df%>%
  filter(!Experiment %in%already_mapped)
#split the df by experiments for the for loop
df_grouped<-df%>%
  group_by(Experiment)%>%
  group_split()
#test case
i=df_grouped[[1]]

##### establish multicore backend #####
mcoptions <- list(preschedule=FALSE, set.seed=FALSE)
#set number of simultainies downloads
paralel_downloads<-4
#set ncores for kallisto and fasterq-dump
ncores <- min(as.integer(detectCores()/paralel_downloads*2),as.integer(detectCores()))
registerDoParallel(paralel_downloads)

##### download and map everthing ######
outputs<-foreach(i=df_grouped, .options.multicore = mcoptions,.inorder=F)%dopar%{
  #path to Kallisto index
  index=kallisto_index
  
  Run_ID<-i %>%
    pull(Run)
  
  output<-i%>%
    pull(Experiment)%>%
    .[1]
  
  output<-i%>%
    pull(Stranded)%>%
    .[1]
  if(!output %in% already_mapped){
    #calls python script download and map multiple
    download_and_map_multiple(index,Run_ID,output,stranded,fasterq_dump_path,kallisto_path,ncores)
  } else {
    "skip"
  }
  
}
