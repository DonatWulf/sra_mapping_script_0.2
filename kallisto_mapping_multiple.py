import subprocess
import os
import time
import glob

#link_p=["SRR1785728","SRR1797830"]

#sorted(glob.glob("SRR12147614*fastq"))

# Downloads and unpacks SRA files form NCBI
def unpack_sra_file(Run_ID,fasterqdump="fasterq-dump",ncores=8,remove=True):
  #run fasterq-dump
  call=fasterqdump+" -e "+str(ncores)+" --split-files {SRAFile}"
  call=call.format(SRAFile=Run_ID).split(" ")
  try:
    subprocess.run(call)#, stderr=os.DEVNULL, stdout=os.DEVNULL
  except:
    print("Error_while_downloading "+Run_ID+" ".join(call))
  #get output files and return them
  output=sorted(glob.glob(Run_ID+"*.fastq"))
  #check if the file is single or paired end
  if len(output) ==1:
    seq_type="SINGLE"
  else:
    seq_type="PAIRED"
  #add files and Paired or Single into a list
  output_file=[" ".join(output),seq_type]
  
  return output_file

def kallisto_mapping(index,files,type_,output,stranded="",kallisto="kallisto",ncores=8,remove=True):
  if stranded != "fr" & stranded != "rf":
    stranded=""
  if stranded == "fr":
    stranded="--fr-stranded "
  if stranded == "rf":
    stranded="--rf-stranded "
  

  print(files)
  for i in files.split(" "):
    if not os.path.isfile(i):
      for j in files.split(" "):
        if os.path.isfile(j):
          os.remove(j)
      return "file_not_found"
  if type_=="SINGLE":
    call=kallisto+" quant -t "+str(ncores)+" -i {index} -o {output}_out "+stranded+"--single -l 200 -s 20 {fastqFiles}"
  else:
    call=kallisto+" quant -t "+str(ncores)+" -i {index} -o {output}_out "+stranded+"{fastqFiles}"
  call=call.format(index=index,output=output,fastqFiles=files).split(" ")
  try:
    subprocess.run(call)
  except:
    print("Error while mapping "+output+" ".join(call))
  for i in files.split(" "):
    os.remove(i)
  return "done"


# downloads and maps multiple Runs from SRA
def download_and_map_multiple(index,link_p,output,stranded,fasterqdump="fasterq-dump",kallisto="kallisto",ncores=8,remove=True):
  all_fastq=""
  all_types=[]
  if type(link_p)==type("a"):
    link_p=[link_p]
  for i in link_p:
    new_files=unpack_sra_file(i,fasterqdump,ncores,remove)
    all_types.append(new_files[1]) # add all types to a list
    all_fastq+=new_files[0] # add all unpacked files to a string separated by " "
    all_fastq+=" "
  if len(set(all_types))!=1:  #test if all paired or single runs are the same.
    return "mixed of single-end and paired-end Runs!"
  type_p=all_types[0]
  all_fastq=all_fastq.rstrip(" ")
  print(all_fastq)
  kallisto_mapping(index,all_fastq,type_p,output,stranded,kallisto,ncores,remove)
  for i in all_fastq.split(" "):
    if os.path.exists(i):
      os.remove(i)
  return "done"


