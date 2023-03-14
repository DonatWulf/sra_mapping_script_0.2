library(argparser)

p <- arg_parser("automatic mapping script for SRA RNA-seq exerpiments with kallisto. kallisto and fasterq-dump need to be installed. If you don't know if the data is unstranded, first or second read stranded check the publication or you can use this tool to check the experiments: https://github.com/signalbash/how_are_we_stranded_here")

p<-add_argument(p, arg="-transcriptome",help="transcriptome fasta file to generate the kallisto index and map the reads",nargs=1,short = "-t")
p<-add_argument(p, arg="-retries",help="number of retries for failed downloads",default=3,short= "-r",nargs=1)
p<-add_argument(p, arg="--check_reads",help="if set the number of processed reads is compared to the provided number of spots",flag = T,short="--c",nargs=1)
p<-add_argument(p, arg="-paralel_downloads",help="how many downloads are run in parallel. This increases the storage requirement. At some point, you get diminishing returns",default=2,short="-p",nargs=1)
p<-add_argument(p, arg="-paralel_kallisto",help="how many threads kallisto should use for mapping. If 0 the number of available threads will be used.",short="-k",default=0,type="integer",nargs=1)
p<-add_argument(p, arg="-SRA_info",help="SRA info file containing the RunID, ExperimentID, LibraryLayout, Stranded, the number of spots comma seperated. If you want to map each run individually, you need to assign an individual ExperimenID or use the RunID as the ExperimentID",short="-s",nargs=1)
p<-add_argument(p, arg="-standard_diviation",help="standard diviation used for mapping",short="-sd",default=20,type="integer",nargs=1)
p<-add_argument(p, arg="-fragment_length",help="fragment length used for mapping",short="-fl",default=200,type="integer",nargs=1)
p<-add_argument(p, arg="-output_file",help="output file name prefix.",short="-o",default="expression_matrix",nargs=1)
p<-add_argument(p, arg="--combine",help="use this flag to just combine individual mappings into the expression matrix",flag = T)


p
args<-parse_args(p)



source("map_all.R")
if(!args$combine){
  
  if(is.na(args$transcriptome)){
    warning("no transcriptome fasta file provided!")
  }
  
  if(is.na(args$SRA_info)){
    warning("no SRA info file provided!")
  }
  
  stopifnot(!(is.na(args$SRA_info)|is.na(args$transcriptome)))
  

  map_all(runinfo_file = args$SRA_info,
           transcriptome_fasta = args$transcriptome,
           retries = args$retries,
           check_spots= args$check_reads,
           paralel_downloads= args$paralel_downloads,
           ncores_= args$paralel_kallisto,
           output_file= args$output_file,
           sd= args$standard_diviation,
           fragment_length= args$fragment_length)
} else {
  combine_all(output_file= args$output_file)
}
