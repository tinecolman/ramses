#!/bin/bash

# append commands
cat <<JOBSCRIPT >> "$OUTPUT_FILE"

#######################################################################
# Get the existing results
#######################################################################

eval "$(ssh-agent -s)"
cd ..
git submodule update --init --recursive
cd benchmarks/results
git checkout main
git pull origin main
cd ..

module load ${MODULE_PYTHON}
python io_timings.py ${CLUSTER} ${LAUNCH_DIR} ${TEST_NAME} >> ${LOGFILE}

# clean up
rm total_time.txt

# push to git
cd results
git add data/timings_${CLUSTER}_${TEST_NAME}.txt
git commit -m 'update benchmark results ${CLUSTER} ${TEST_NAME}'
git push
cd ..
JOBSCRIPT
