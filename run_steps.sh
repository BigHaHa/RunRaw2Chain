#!/bin/bash
#############################################################
echo ""
echo "========================= START ========================="

bit=$1 #step sequence: raw->reco; reco->TreeNA61; TreeNA61->DataTree; set 1 if step is turned on, 0 if off. For example: 010 == reco->TreeNA61
filelist=$2 #file with list of files, one job will be submitted for each file in list
global_key=$3 #configuration of the reconstruction, for example, 16_003
output_dir=$4
castor_output_dir=$5

shine_dir="/afs/cern.ch/work/v/viblinov/public/reconstruction/SHINE"
# queue="8nh" #options: "8nh" "1nd"
queue="1nh" #options: "8nh" "1nd"
# output_dir="/afs/cern.ch/work/v/viblinov/public/reconstruction/output"
# castor_output_dir="/castor/cern.ch/user/v/viblinov"

maxfiles=1000 #maximum number of chunks to be analised

#############################################################
echo $bit > bit.txt
raw_to_reco=`eval cut -c 1 bit.txt`
reco_to_TreeNA61=`eval cut -c 2 bit.txt`
TreeNA61_to_DataTree=`eval cut -c 3 bit.txt`
rm bit.txt

if [ $raw_to_reco -eq 0 ]
then
  if [ $reco_to_TreeNA61 -eq 0 ]
  then
    if [ $TreeNA61_to_DataTree -eq 0 ]
    then
      echo "Empty step sequence: nothing to do."
      exit 3
    fi
    if [ $TreeNA61_to_DataTree -eq 1 ]
    then
      echo "Step sequence: TreeNA61 -> DataTree"
      queue="1nh"
      raw_to_reco=0
      reco_to_TreeNA61=0
      TreeNA61_to_DataTree=1    
    fi
  fi
  if [ $reco_to_TreeNA61 -eq 1 ]
  then
    if [ $TreeNA61_to_DataTree -eq 0 ]
    then
      echo "Step sequence: reco -> TreeNA61"
      queue="1nh"
      raw_to_reco=0
      reco_to_TreeNA61=1
      TreeNA61_to_DataTree=0
    fi
    if [ $TreeNA61_to_DataTree -eq 1 ]
    then
      echo "Step sequence: reco -> TreeNA61 -> DataTree"
      queue="8nh"
      raw_to_reco=0
      reco_to_TreeNA61=1
      TreeNA61_to_DataTree=1
    fi
  fi
fi
if [ $raw_to_reco -eq 1 ]
then
  if [ $reco_to_TreeNA61 -eq 0 ]
  then
    if [ $TreeNA61_to_DataTree -eq 0 ]
    then
      echo "Step sequence: raw -> reco"
      queue="8nh"
      raw_to_reco=1
      reco_to_TreeNA61=0
      TreeNA61_to_DataTree=0
    fi
    if [ $TreeNA61_to_DataTree -eq 1 ]
    then
      echo "Impossible step sequence: raw -> reco -x- TreeNA61 -> DataTree"
      exit 4
    fi
  fi
  if [ $reco_to_TreeNA61 -eq 1 ]
  then
    if [ $TreeNA61_to_DataTree -eq 0 ]
    then
      echo "Step sequence: raw -> reco -> TreeNA61"
      queue="8nh"
      raw_to_reco=1
      reco_to_TreeNA61=1
      TreeNA61_to_DataTree=0
    fi
    if [ $TreeNA61_to_DataTree -eq 1 ]
    then
      echo "Step sequence: raw -> reco -> TreeNA61 -> DataTree"
      queue="8nh"
      raw_to_reco=1
      reco_to_TreeNA61=1
      TreeNA61_to_DataTree=1    
    fi
  fi
fi
#############################################################

#queue="1nh" #TEST!!!

# main_dir="$output_dir"_$(date +"%T")
timestamp=$(date +%Y%m%d_%H%M%S)
main_dir="$output_dir"/"$timestamp"
castor_dir="$castor_output_dir"/"$timestamp"
# main_dir="${main_dir//:/_}"
mkdir -p "$main_dir"
echo "Output directory: ""$main_dir"

if [ $raw_to_reco -eq 1 ]
then
  nsmkdir "$castor_dir"
  nsmkdir "$castor_dir"/reco
  mkdir -p "$main_dir"/reco
fi
if [ $reco_to_TreeNA61 -eq 1 ]
then
  mkdir -p "$main_dir"/TreeNA61
fi
if [ $TreeNA61_to_DataTree -eq 1 ]
then
  mkdir -p "$main_dir"/DataTree
fi

log_dir="$main_dir"/info
mkdir -p "$log_dir"
mkdir -p "$log_dir"/batch
mkdir -p "$log_dir"/shine
rsync -a ./run_steps.sh "$log_dir"/batch/
rsync -a ./run.sh "$log_dir"/batch/
rsync -a ./runModuleSeq.sh "$log_dir"/batch/
rsync -a ./EventFileReader.xml "$log_dir"/batch/
rsync -a ./FlowQA.xml "$log_dir"/batch/
rsync -a ./ShineFileExporter.xml "$log_dir"/batch/
rsync -a ./bootstrap.xml.in "$log_dir"/batch/
rsync -a ./Makefile "$log_dir"/batch/
rsync -a $filelist "$log_dir"/batch/filelist
rsync -a $filelist.conf "$log_dir"/batch/filelist.conf

parameters_file="$log_dir"/batch/parameters
if [ -e $parameters_file ]
then
  rm "$parameters_file"
fi
echo "export BIT=""$bit" >> $parameters_file
echo "export FILELIST=""$log_dir"/batch/filelist >> $parameters_file
echo "export GLOBAL_KEY=""$global_key" >> $parameters_file
echo "export OUTPUT_DIR=""$output_dir" >> $parameters_file
echo "export CASTOR_OUTPUT_DIR=""$castor_output_dir" >> $parameters_file

if [ $raw_to_reco -eq 0 ]
then
  if [ $reco_to_TreeNA61 -eq 1 ]
  then
    rsync -a ./ModuleSequenceRecoToTreeNA61.xml "$log_dir"/batch/ModuleSequence.xml
  fi
else
  if [ $reco_to_TreeNA61 -eq 0 ]
  then
    rsync -a ./ModuleSequenceRawToReco.xml "$log_dir"/batch/ModuleSequence.xml
  else
    rsync -a ./ModuleSequenceRawToRecoToTreeNA61.xml "$log_dir"/batch/ModuleSequence.xml    
  fi
fi
temp_dir="$main_dir"/temp

#############################################################

inputfile=""
cd "$log_dir"/batch
pwd
while read inputfile; do
  short_inputfile=`echo $inputfile | cut -f 2 -d "-" | cut -f 1 -d "."`
  logfile="$log_dir"/shine/"$short_inputfile".log
  echo "--------------------"$short_inputfile"--------------------"
#   echo "Submit the job for "$short_inputfile
#   echo "Shine log file = "$logfile
  iscastor=`echo "$inputfile" | grep castor | wc -l`
#   echo "-q" "$queue" "-o" "$logfile" "run.sh" "$shine_dir" "$filelist"".conf" "$inputfile" "$main_dir" "$castor_dir" "$global_key" "$short_inputfile" "$iscastor" "$bit"
  bsub -q "$queue" -o "$logfile" run.sh "$shine_dir" "$filelist".conf "$inputfile" "$main_dir" "$castor_dir" "$global_key" "$short_inputfile" "$iscastor" "$bit"
#   . run.sh "$shine_dir" "$filelist".conf "$inputfile" "$main_dir" "$castor_dir" "$global_key" "$short_inputfile" "$iscastor" "$bit"
done <"$filelist"
echo "------------------------------------------------"
cd -

#############################################################

echo "========================= END ========================="
echo ""
