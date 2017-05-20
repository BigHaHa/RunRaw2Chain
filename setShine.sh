#!/bin/bash

readonly shine_root="/afs/cern.ch/work/v/viblinov/public/SHINE"
. "${shine_root}/shine_src/Tools/Scripts/env/lxplus_32bit_slc6.sh"
eval $("${shine_root}/shine_install/bin/shine-offline-config" --env-sh)
