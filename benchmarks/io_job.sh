#!/bin/bash

# set jobscript params
NBNODES=1
NTASKS_PER_NODE=1
JOB_NAME=io-${TEST_NAME}
source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/job_script_params.sh

# append commands
cat <<JOBSCRIPT > "$OUTPUT_FILE"
module load ${MODULE_PYTHON}
python io_timings.py ${CLUSTER} ${LAUNCH_DIR} ${TEST_NAME} >> ${LOGFILE}"

# clean up
rm total_time.txt

# push to git
git add results/timings_${CLUSTER}_${TEST_NAME}.txt
git commit -m 'update benchmark results ${CLUSTER} ${TEST_NAME}'
#git push

JOBSCRIPT
