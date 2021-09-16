#link="https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos1/sra-pub-run-1/SRR3418027/SRR3418027.1"
#type="SINGLE"
Run_ID="DRR016685"
link_p="DRR016685"
#link_p="https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos1/sra-pub-run-2/ERR476705/ERR476705.1"
#type_p="PAIRED"
#index="solyc4.0.idx"

import subprocess
import os
import time

def unpack_sra_file_new(Run_ID,type_,remove=True):
  if type_=="PAIRED":
    call="/usr/bin/fasterq-dump -e 7 --split-files {SRAFile}".format(SRAFile=Run_ID).split(" ")
    out_file=Run_ID+"_1.fastq"+ " " +Run_ID+"_2.fastq"
  else:
    call="/usr/bin/fasterq-dump -e 7 {SRAFile}".format(SRAFile=Run_ID).split(" ")
    out_file=Run_ID+".fastq"
  subprocess.call(call)#, stderr=os.DEVNULL, stdout=os.DEVNULL
  #for i in out_file.split(" "):
  #  subprocess.call(["gzip",i])
  #out_file_gz=out_file.replace("fastq","fastq.gz")
  return out_file




#def unpack_sra_file(URL,type_,remove=True):
#  subprocess.call(["wget","-nv","-c",URL], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
#  time.sleep(5)
#  subprocess.call(["wget","-nv","-c",URL], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
#  
#  file_name=URL.split("/")[-1]
#  if not os.path.isfile(file_name):
#    return "NA"
#  if type_=="PAIRED":
#    call="fasterq-dump -e 7 --split-files {SRAFile}".format(SRAFile=file_name).split(" ")
#    out_file=file_name+"_1.fastq"+ " " +file_name+"_2.fastq"
#  else:
#    call="fasterq-dump -e 7 {SRAFile}".format(SRAFile=file_name).split(" ")
#    out_file=file_name+".fastq"
#  subprocess.call(call, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
#  os.remove(file_name)
  #for i in out_file.split(" "):
  #  subprocess.call(["gzip",i])
  #out_file_gz=out_file.replace("fastq","fastq.gz")
#  return out_file

def kallisto_mapping(index,files,type_,output,remove=True):
  print(files)
  for i in files.split(" "):
    if not os.path.isfile(i):
      for j in files.split(" "):
        if os.path.isfile(j):
          os.remove(j)
      return "file_not_found"
  if type_=="SINGLE":
    call="/usr/bin/kallisto quant -t 7 -i {index} -o {output}_out -t 1 --single -l 200 -s 20 {fastqFile1}".format(index=index,output=output,fastqFile1=files).split(" ")
  else:
    call="/usr/bin/kallisto quant -t 7 -i {index} -o {output}_out {fastqFile1}".format(index=index,output=output,fastqFile1=files).split(" ")
  subprocess.call(call, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
  for i in files.split(" "):
    os.remove(i)
  return "done"

#def download_and_map(index,link_p,type_p,remove=True):
#  fastqs=unpack_sra_file(link_p,type_p,remove)
#  kallisto_mapping(index,fastqs,remove)
#  return "done"

def download_and_map_multiple(index,link_p,type_p,output,remove=True):
  all_fastq=""
  if type(link_p)==type("a"):
    link_p=[link_p]
  for i in link_p:
    all_fastq+=unpack_sra_file_new(i,type_p,remove)
    all_fastq+=" "
  all_fastq=all_fastq.rstrip(" ")
  print(all_fastq)
  kallisto_mapping(index,all_fastq,type_p,output,remove)
  for i in all_fastq.split(" "):
    if os.path.exists(i):
      os.remove(i)
  return "done"

#download_and_map_multiple(index,["https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos2/sra-pub-run-13/ERR2204417/ERR2204417.1","https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos2/sra-pub-run-13/ERR2204418/ERR2204418.1"],"SINGLE","test_mapping",remove=True)
