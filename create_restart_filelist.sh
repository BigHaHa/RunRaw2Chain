#!/bin/bash
echo ""
job_dir=$1 #for instance, /afs/cern.ch/work/v/viblinov/public/reconstruction/output/20170213_170051

filelist="$job_dir"/info/batch/filelist

tempfilelist_done="./tempfilelist_done"
tempfilelist_notdone="./tempfilelist_notdone"
if [ -e $tempfilelist_notdone ]
then
  rm $tempfilelist_notdone
fi
if [ -e $tempfilelist_done ]
then
  rm $tempfilelist_done
fi
if [ -e "$job_dir"/DataTree ]
then
  echo "Checking DataTree files..."
  ls -1 "$job_dir"/DataTree | cut -d "." -f 1 > $tempfilelist_done
else
  if [ -e "$job_dir"/TreeNA61 ]
  then
    echo "Checking TreeNA61 files..."
    ls -1 "$job_dir"/TreeNA61 | cut -d "." -f 1 > $tempfilelist_done
  else
    if [ -e "$job_dir"/reco ]
    then
      echo "Cheking reco paths..."
      ls -1 "$job_dir"/reco | cut -d "." -f 1 > $tempfilelist_done
    else
      echo "No output directories (reco, TreeNA61, DataTree) found!"
      exit 3
    fi
  fi
fi

inputfile=""
while read inputfile; do
  short_inputfile=`echo $inputfile | cut -f 2 -d "-" | cut -f 1 -d "."`
  declare -i ifdone=`eval grep "$short_inputfile" "$tempfilelist_done" | wc -l`
  if [ $ifdone -eq 0 ]
  then
    echo $inputfile >> $tempfilelist_notdone
  fi
done <"$filelist"
if [ -e $tempfilelist_notdone ]
then
  mv $tempfilelist_notdone "$job_dir"/info/batch/filelist.restart
  cp "$job_dir"/info/batch/filelist.conf "$job_dir"/info/batch/filelist.restart.conf
  echo "Filelist for restart was created: ""$job_dir"/info/batch/filelist.restart
  echo "Restart the jobs with the command: "./restart_steps.sh "$job_dir"/info/batch/parameters
else
  echo "All output files were created."
fi
if [ -e $tempfilelist_notdone ]
then
  rm $tempfilelist_notdone
fi
if [ -e $tempfilelist_done ]
then
  rm $tempfilelist_done
fi
echo ""
