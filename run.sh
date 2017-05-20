#!/bin/bash

timestamp_start=$(date +%Y%m%d_%H%M%S)

shine_dir=$1
configfile=$2
inputfile=$3
main_dir=$4
castor_dir=$5
globalkey=$6
short_inputfile=$7
iscastor=$8
bit=$9

source "$batch_dir"/"$configfile"
vertexfit=$RUN_STEPS_VERTEX_FIT
magfield=$RUN_STEPS_MAGNETIC_FIELD

bootstrapfile="bootstrap.xml"

temp_dir=/pool/lsf/`whoami`/"$short_inputfile"
# temp_dir=/afs/cern.ch/work/v/viblinov/public/reconstruction/scripts/test/"$short_inputfile"
rm -rf $temp_dir
mkdir -p $temp_dir

batch_dir="$main_dir"/info/batch
cp "$batch_dir"/*xml* "$temp_dir"
cp "$batch_dir"/*sh "$temp_dir"
cp "$batch_dir"/Makefile "$temp_dir"


temp_inputfile="$temp_dir"/"$short_inputfile".in
temp_outputfile="$temp_dir"/"$short_inputfile".out
echo $bit > bit.txt
raw_to_reco=`eval cut -c 1 bit.txt`
reco_to_TreeNA61=`eval cut -c 2 bit.txt`
TreeNA61_to_DataTree=`eval cut -c 3 bit.txt`
rm bit.txt
if [ $raw_to_reco -eq 1 ]
then
  temp_inputfile="$temp_dir"/"$short_inputfile".raw
else
  if [ $reco_to_TreeNA61 -eq 1 ]
  then
    temp_inputfile="$temp_dir"/"$short_inputfile".reco.root
  else
    echo TODO!!! ###################################################### TODO    
  fi
fi

if [ $iscastor -eq 1 ]
then
  export STAGE_HOST=castorpublic
  export RFIO_USE_CASTOR_V2=YES
  export STAGE_SVCCLASS=amsuser
  export CASTOR_INSTANCE=castorpublic
  export STAGE_SVCCLASS=na61
  stager_get -M $inputfile
  xrdcp "root://castorpublic.cern.ch//"$inputfile $temp_inputfile
else
  rsync -a $inputfile $temp_inputfile
fi

echo "Input file = "$inputfile
echo "Temporary input file = "$temp_inputfile
echo "Temporary output file = "$temp_outputfile
echo "Bootstrap file = "$temp_dir/$bootstrapfile
echo "Vertex fit = "$vertexfit
echo "Global key = "$globalkey
echo "Magnetic field = "$magfield
echo ""
echo "========================================"
echo ""
echo "Contents of the temporary directory:"
ls -1 "$temp_dir"
echo ""
echo "========================================"
echo ""
cd "$temp_dir"

. $shine_dir/setShine
. runModuleSeq.sh -i "$temp_inputfile" -o "$temp_outputfile" -b "$bootstrapfile" -k "$globalkey" -v "$vertexfit" -m "$magfield"

echo "========================================"
echo ""
echo "Contents of the temporary directory:"
ls -1 "$temp_dir"
echo ""
echo "========================================"
echo ""

if [ $raw_to_reco -eq 1 ]
then
  xrdcp "$temp_outputfile".shoe.root root://castorpublic.cern.ch/"$castor_dir"/reco/run-"$short_inputfile".reco.root
#   rsync -a "$temp_outputfile".shoe.root "$main_dir"/reco/"$short_inputfile".reco.root
  echo "$castor_dir"/reco/run-"$short_inputfile".reco.root >> "$main_dir"/reco/run-"$short_inputfile".path_to_castor.txt
  echo "Output reco file: ""$castor_dir"/reco/run-"$short_inputfile".reco.root
fi

if [ $reco_to_TreeNA61 -eq 1 ]
then
  rsync -a "$temp_outputfile".qa.root "$main_dir"/TreeNA61/run-"$short_inputfile".TreeNA61.root
  echo "Output TreeNA61 file: ""$main_dir"/TreeNA61/run-"$short_inputfile".TreeNA61.root
fi

if [ $TreeNA61_to_DataTree -eq 1 ]
then
  echo TODO!!! ###################################################### TODO   
fi


echo ""
echo "========================================"
echo ""
echo "Job finished."

timestamp_end=$(date +%Y%m%d_%H%M%S)
echo "TIME: ""$timestamp_start"" -- ""$timestamp_end"
