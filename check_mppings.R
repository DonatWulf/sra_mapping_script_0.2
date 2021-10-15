library(tidyverse)
library(jsonlite)
#setwd("/vol/cluster-data/dwulf/mapping_new/_failed_mappings/combine_table_check_integrity/")

#function to extract the number of processed reads by kallisto
get_n_processed<-function(x){
  counts<-c()
  for(i in x){
    new<-read_json(i)
    counts<-c(counts,new$n_processed)
  }
  return(counts)
}


#function to extract the number of pseudoaligned reads by kallisto
get_p_pseudoaligned<-function(x){
  p_pseudoaligned<-c()
  for(i in x){
    new<-read_json(i)
    p_pseudoaligned<-c(p_pseudoaligned,new$p_pseudoaligned)
  }
  return(p_pseudoaligned)
}


# list all run_info files
experiments<-list.files(pattern="run_info",recursive = T)

#read Runinfo file with total_bases and experiment column
df<-read_csv("Selection/SraRunInfo_Z_mays.csv",guess_max = 100000)

experiments<-experiments%>%
  enframe("number","path")%>%
  mutate(Experiment=str_remove(path,"/run.*"))%>%
  filter(file.size(path)>0)%>%
  mutate(n_processed=get_n_processed(path),
         Experiment=str_remove(Experiment,"\\..*"),
         p_pseudoaligned=get_p_pseudoaligned(path))%>%
  mutate(Experiment=str_remove(Experiment,"_out"))



target_bases<-df%>%
  group_by(Experiment)%>%
  summarise(total_bases=sum(spots))



experiments%>%
  left_join(target_bases,by=c("Experiment"))%>%
  left_join(df,by=c("Experiment"="Run"))%>%
  mutate(difference=total_bases-n_processed)%>%
  filter(abs(difference)>1000)%>%
  arrange(desc(difference))%>%
  write_tsv("denbi_dw_is_needed_to_map.tsv")




experiments_70<-experiments%>%
  filter(p_pseudoaligned<70)

experiments%>%
  ggplot(aes(p_pseudoaligned))+
  geom_density()

experiments%>%
  ggplot(aes(p_pseudoaligned))+
  geom_density()
