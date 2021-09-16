library(tidyverse)
#library(tidyverse, lib.loc = "/mnt/data/R/library/")
library(doParallel)
library(reticulate)
#setwd("/mnt/nwdata/2021_sollyc_nw/Network_mapping/")
source_python("kallisto_mapping_multiple.py")
df<-read_tsv("2021-07-07_Slyc_selected_sra-experiments_download.tsv",guess_max = 22000)
colnames(df)
#df<-df%>%dplyr::rename("Experiment"="ExperimentAccession")
##bartus<-read_tsv("already_done_bartus.tsv_new")
##denbi<-read_tsv("already_done_denbi_big.tsv_new")
#failed_mappings<-read_tsv("barley_difference_in_number_of_reads.tsv")
##all<-bartus%>%
##  bind_rows(denbi)%>%
##  pull(value)%>%
##  str_remove("_.*")
#df<-df%>%filter(Experiment %in% failed_mappings$Experiment.Accession)
##df<-df%>%
##  filter(is.na(mapped) | duplicated(Experiment.Accession) & Selection!="0")%>%
##  filter(!Experiment.Accession %in% all)


already_done<-c("adf")

df<-df%>%
  filter(!Experiment %in%already_done)


df_grouped<-df%>%
  group_by(Experiment)%>%
  group_split()

df_grouped_new<-df_grouped


i=df_grouped[[1]]



i<-df_grouped_new[[2]]
mcoptions <- list(preschedule=FALSE, set.seed=FALSE)
#set number of cores
ncores <- 4
registerDoParallel(ncores)
outputs<-foreach(i=df_grouped_new, .options.multicore = mcoptions,.inorder=F)%dopar%{
  #path to Kallisto index
  index="solyc4.0.idx"
  
  
  Run_ID<-i %>%
    pull(Run)
  
  type=i%>%
    pull(LibraryLayout)%>%
    .[1]
  output<-i%>%
    pull(Experiment)%>%
    .[1]
  
  
  
  if(!output %in% already_done){
    #calls python script download and map multiple
    download_and_map_multiple(index,Run_ID,type,output)
  } else {
    "skip"
  }
  
}
