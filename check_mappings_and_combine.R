library(tidyverse)
library(jsonlite)
get_n_processed<-function(x){
  counts<-c()
  for(i in x){
    new<-read_json(i)
    counts<-c(counts,new$n_processed)
  }
  return(counts)
}

get_p_pseudoaligned<-function(x){
  p_pseudoaligned<-c()
  for(i in x){
    new<-read_json(i)
    p_pseudoaligned<-c(p_pseudoaligned,new$p_pseudoaligned)
  }
  return(p_pseudoaligned)
}


get_n_pseudoaligned<-function(x){
  n_pseudoaligned<-c()
  for(i in x){
    new<-read_json(i)
    n_pseudoaligned<-c(n_pseudoaligned,new$n_pseudoaligned)
  }
  return(n_pseudoaligned)
}

read_json(list.files(pattern="run_info",recursive = T)[100])


experiments<-list.files(pattern="run_info",recursive = T)
experiments<-experiments%>%
  enframe("number","path")%>%
  mutate(Experiment=str_remove(path,"/run.*"))%>%
  filter(file.size(path)>0)%>%
  mutate(n_processed=get_n_processed(path),
         Experiment=str_remove(Experiment,"\\..*"),
         p_pseudoaligned=get_p_pseudoaligned(path),
         n_pseudoaligned=get_n_pseudoaligned(path))%>%
  mutate(Experiment=str_remove(Experiment,"_out"))

df<-read_csv("SRARunInfo_Sb.csv",guess_max = 100000)

target_bases<-df%>%
  group_by(Experiment)%>%
  summarise(total_bases=sum(spots))



remappings<-experiments%>%
  left_join(target_bases,by=c("Experiment"))%>%
  left_join(df,by=c("Experiment"="Run"))%>%
  mutate(difference=total_bases-n_processed)%>%
  filter(abs(difference)>1000)%>%
  arrange(desc(difference))%>%
  pull(Experiment)


df%>%
  filter(Experiment %in% remappings)%>%
  write_csv("SRARunInfo_Sb_new.csv")

remappings%>%
  str_c("_out")%>%
  unlink(recursive = T)


experiments_70<-experiments%>%
  filter(p_pseudoaligned<70)

experiments%>%
  ggplot(aes(p_pseudoaligned))+
  geom_density()



experiments%>%
  ggplot(aes(n_processed))+
  geom_density()+
  geom_vline(xintercept=5e6)+
  geom_vline(xintercept=10e6)+
  geom_vline(xintercept=7.5e6)

experiments%>%
  filter(n_pseudoaligned>7.5e6)%>%
  filter(p_pseudoaligned<70 & p_pseudoaligned>60)%>%
  left_join(df,by="Experiment")%>%
  write_tsv("Barley_exp_further_curration.tsv")

experiments%>%
  filter(n_pseudoaligned>7.5e6)%>%
  filter(p_pseudoaligned>=70 )%>%
  left_join(df,by="Experiment")

good_experiments<-experiments%>%
  filter(n_pseudoaligned>7.5e6)%>%
  filter(p_pseudoaligned>=70 )%>%
  mutate(path=str_replace(path,"run_info.json","abundance.tsv"))%>%
  pull(path)

expression_matrix<-read_tsv(good_experiments[1])%>%
  mutate(target_id=str_remove(target_id,"\\.\\d*$"))%>%
  select(target_id)
for(i in good_experiments){
  experiment<-str_remove(i,"_out.*")
  x<-read_tsv(i)%>%
    select(tpm)
  colnames(x)<-experiment
  expression_matrix<-x%>%
    bind_cols(expression_matrix,.)
}


dim(expression_matrix)
expression_matrix%>%
  column_to_rownames("target_id")%>%
  as.matrix()%>%
  saveRDS("expression_matrix.Rds")


