library(tidyverse)
library(jsonlite)
library(doParallel)





map_all<-function(runinfo_file,transcriptome_fasta,retries=3,check_spots=F,paralel_downloads=2,ncores_=0,output_file="expr_matrix",sd=20,fragment_length=200){
  config_<-read_delim("ProgPath.config",delim=": ",col_names=F)%>%
    mutate(X2=str_remove_all(X2," *"))
  fasterq_dump_path<-config_%>%
    filter(X1=="fasterq-dump")%>%
    pull(X2)
  kallisto_path<-config_%>%
    filter(X1=="kallisto")%>%
    pull(X2)
  
  
  n_read_dist=1000
  
  
  print(runinfo_file)
  
  
  expected_columns<-c("Experiment","Run","LibraryLayout","Stranded","spots")
  
  found_columns<-read_csv(runinfo_file)%>%
    colnames()
  missing_columns<-expected_columns[!expected_columns %in% found_columns]
  
  if(length(missing_columns)!=0){
    for(missing_col in missing_columns){
      warning(str_c("Column ",missing_col,"is missing from the RunInfo file!"))
      
    }
    stopifnot(length(missing_columns)==0)
  }
  
  
  system(str_c(kallisto_path," index -i index.idx ",transcriptome_fasta))
  
  dir.create("mappings",showWarnings =F)
  
  ##### establish multicore backend #####
  mcoptions <- list(preschedule=FALSE, set.seed=FALSE)
  #set ncores for kallisto and fasterq-dump
  
  ncores <- min(as.integer(detectCores()/paralel_downloads*2),as.integer(detectCores()))
  if(ncores_ !=0) ncores<-ncores_
  registerDoParallel(paralel_downloads)
  
  
  all_mappings<-NULL
  for(i in 1:retries){
    mapped_exps<-list.files("mappings",pattern="abundance.tsv",recursive=T)%>%
      str_remove("/abundance.tsv")
    
    RunInfoFile<-read_csv(runinfo_file)%>%
      filter(!Experiment %in% mapped_exps)%>%
      group_by(Experiment)%>%
      group_split()
    
    
    mapping_try<-foreach(i=RunInfoFile, .options.multicore = mcoptions, .inorder=F, .combine=bind_rows) %dopar%{
      
      ID=i$Experiment[1]
      
      unpacked_files<-NULL
      n_files<-NULL
      for(j in i$Run){
        system(str_c(fasterq_dump_path, " " ,j))
        
        n_files<-list.files(pattern=j)%>%
          length()%>%
          c(n_files)
        
        unpacked_files<-list.files(pattern=j)%>%
          str_c(collapse = " ")%>%
          str_c(unpacked_files,sep=" ")
        
      }
      single_or_paired="none"
      if(sum(n_files ==2)==length(n_files)) single_or_paired ="paired"
      if(sum(n_files ==1)==length(n_files)) single_or_paired ="single"
      if(single_or_paired=="none")next
      
      if(single_or_paired=="paired"){
        
        if(i$Stranded[1]=="fr") system(str_c("kallisto quant -i index.idx -o mappings/",ID," --fr-stranded -t ",ncores," ", unpacked_files ))
        if(i$Stranded[1]=="rf") system(str_c("kallisto quant -i index.idx -o mappings/",ID," --rf-stranded -t ",ncores," ", unpacked_files ))
        if(i$Stranded[1]=="us") system(str_c("kallisto quant -i index.idx -o mappings/",ID," -t ",ncores," ", unpacked_files ))
        
      } else {
        
        if(i$Stranded[1]=="fr") system(str_c("kallisto quant -i index.idx -o mappings/",ID," --fr-stranded --single -t ",ncores," -l ",fragment_length," -s ",sd," ", unpacked_files))
        if(i$Stranded[1]=="rf") system(str_c("kallisto quant -i index.idx -o mappings/",ID," --rf-stranded --single -t ",ncores," -l ",fragment_length," -s ",sd," ", unpacked_files))
        if(i$Stranded[1]=="us") system(str_c("kallisto quant -i index.idx -o mappings/",ID," ",ncores," --single -l ",fragment_length," -s ",sd," ", unpacked_files))
        
      }
      
      unlink(str_split(unpacked_files,pattern=" ")[[1]])
      
      
      if(!abs(fromJSON(str_c("mappings/",ID,"/run_info.json"))$n_processed-sum(i$spots))<=n_read_dist & check_spots) {
        unlink(str_c("mappings/",ID),recursive=T)
        warning(str_c(ID,": Number of processed reads does not match number of reported spots in sample file"))
        NULL
      }else{
        read_tsv(str_c("mappings/",ID,"/abundance.tsv"))%>%
          mutate(experiment=ID)
      }
      
    }
    all_mappings<-all_mappings%>%
      bind_rows(mapping_try)
  }
  
  
  
  all_mappings_tpm<-all_mappings%>%
    select(target_id,tpm,experiment)%>%
    pivot_wider(names_from=experiment,values_from = tpm)
  
  
  all_mappings_tpm%>%
    write_tsv(str_c(output_file,"_tpms.tsv.gz"))
  
  
  all_mappings_counts<-all_mappings%>%
    select(target_id,est_counts,experiment)%>%
    pivot_wider(names_from=experiment,values_from = est_counts)
  
  all_mappings_counts%>%
    write_tsv(str_c(output_file,"_est_counts.tsv.gz"))

  list.dirs()%>%
    .[str_detect(.,"fasterq\\.tmp")]%>%
    unlink(recursive = T)
}


combine_all<-function(output_file="expr_matrix"){
  all_mapping_files<-list.files("mappings")%>%
    str_c("mappings/",.,"/abundance.tsv")
  all_mappings<-NULL
  for(i in all_mapping_files){
    ID=i%>%
      str_remove_all("mappings/|/abundance.tsv")
    all_mappings<-read_tsv(str_c("mappings/",ID,"/abundance.tsv"))%>%
      mutate(experiment=ID)%>%
      bind_rows(all_mappings)
  }
  
  all_mappings_tpm<-all_mappings%>%
    select(target_id,tpm,experiment)%>%
    pivot_wider(names_from=experiment,values_from = tpm)
  
  
  all_mappings_tpm%>%
    write_tsv(str_c(output_file,"_tpms.tsv.gz"))
  
  
  all_mappings_counts<-all_mappings%>%
    select(target_id,est_counts,experiment)%>%
    pivot_wider(names_from=experiment,values_from = est_counts)
  
  all_mappings_counts%>%
    write_tsv(str_c(output_file,"_est_counts.tsv.gz"))

}
  

