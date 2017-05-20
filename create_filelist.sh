#!/bin/bash
#############################################################

configfile=$1 #The file containing config info like year, target, projectile, energy, target_status, magnetic_field, run_type
data_source=$2 #Point which kind of files are the source data for the given task: 0=raw, 1=reco, 2=TreeNA61, 3=user-defined
output_filelist=$3 #the full name of the file with the list of files
user_defined_source_path=$4 #the full path for the data files
user_source_data_from_castor=$5 #=1 is the files are on castor

source $configfile

year=$FILELIST_YEAR
target=$FILELIST_TARGET
projectile=$FILELIST_PROJECTILE
energy=$FILELIST_ENERGY
target_status=$FILELIST_TARGET_STATUS
magnetic_field=$FILELIST_MAGNETIC_FIELD
run_type=$FILELIST_RUN_TYPE

runTable=$FILELIST_RUN_TABLE

echo ===================================================
echo "Year:             "$year
echo "Target:           "$target
echo "Projectile:       "$projectile
echo "Energy:           "$energy
echo "Target status:    "$target_status
echo "Magnetic field:   "$magnetic_field
echo "Run type:         "$run_type
echo "Run table:        "$runTable
echo ===================================================

if [ $output_filelist -eq 0 ]
then
  output_filelist=./filelists/filelist_"$projectile""$energy""$target"_y"$year"_t"$target_status"_mf"$magnetic_field"_"$run_type"
  echo "Automatically created filename for output list: ""$output_filelist"
fi

rm $output_filelist
rm $output_filelist.conf

if [ $magnetic_field -eq 1 ]
then
  echo "export RUN_STEPS_MAGNETIC_FIELD=\"on\"" >> $output_filelist.conf
else
  echo "export RUN_STEPS_MAGNETIC_FIELD=\"off\"" >> $output_filelist.conf
fi
echo "export RUN_STEPS_VERTEX_FIT=\"pA\"" >> $output_filelist.conf

if [ $magnetic_field -eq 1 ]
then
# echo "grep "$projectile"@"$energy"GeV/c-Pb $runTable | grep "run-" | grep "$energy GeV/c" | grep "$target_status" | cut -f 1 | cut -b 2-6"
grep "$projectile"@"$energy"GeV/c-Pb $runTable | grep "$energy GeV/c" | grep "$target_status" | cut -f 1 | cut -b 2-6 >> ./temp_output_filelist
fi
if [ $magnetic_field -eq 0 ]
then
# echo "grep "$projectile"@"$energy"GeV/c-Pb $runTable | grep "run-" | grep "0 GeV/c" | grep "$target_status" | cut -f 1 | cut -b 2-6"
grep "$projectile"@"$energy"GeV/c-Pb $runTable | grep "0 GeV/c" | grep "$target_status" | cut -f 1 | cut -b 2-6 >> ./temp_output_filelist
fi

if [ $data_source -eq 0 ]
then
castor_dir=/castor/cern.ch/na61/"$year"/"$projectile"/"$target""$energy"
fi
if [ $data_source -eq 1 ]
then
castor_dir=/castor/cern.ch/user/v/viblinov/reco/"$year"/"$projectile"/"$target""$energy"
fi
if [ $data_source -eq 2 ]
then
castor_dir=/castor/cern.ch/user/v/viblinov/TreeNA61/"$year"/"$projectile"/"$target""$energy"
fi
if [ $data_source -eq 3 ]
then
castor_dir=$user_defined_source_path
fi

# echo $castor_dir

while read run_number; do
if [ $data_source -eq 3 ]
then
  if [ $user_source_data_from_castor -eq 1 ]
  then
#     nsls $castor_dir | grep "run-" | grep -e $run_number | cut -d "." -f 1
    nsls $castor_dir | grep "run-" | grep -e $run_number >> ./temp_output_filelist_1
  else
#     ls -1 $castor_dir | grep "run-" | grep -e $run_number | cut -d "." -f 1
    ls -1 $castor_dir | grep "run-" | grep -e $run_number >> ./temp_output_filelist_1
  fi
else
#   nsls $castor_dir | grep "run-" | grep -e $run_number | cut -d "." -f 1
  nsls $castor_dir | grep "run-" | grep -e $run_number >> ./temp_output_filelist_1
fi
done <"./temp_output_filelist"

filename=""
while read filename; do
  echo "$castor_dir"/"$filename" >> "$output_filelist"
done <"./temp_output_filelist_1"

rm ./temp_output_filelist
rm ./temp_output_filelist_1

echo "Output list in "$output_filelist