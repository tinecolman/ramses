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
mkdir -p data_${BRANCH}

module load ${MODULE_PYTHON}
python io_timings.py ${CLUSTER} "${LAUNCH_DIR}/${TEST_NAME}" ${BRANCH} >> ${LOGFILE}

# clean up
rm total_time.txt

# push to git
git add data_${BRANCH}/timings_${CLUSTER}_${TEST_NAME}.txt
git commit -m 'update ${TEST_NAME} benchmark results of branch ${BRANCH} on ${CLUSTER}'
git push
cd ..
JOBSCRIPT
