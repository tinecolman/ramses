#!/bin/bash

# append commands
cat <<JOBSCRIPT >> "$OUTPUT_FILE"
module load ${MODULE_PYTHON}
python io_timings.py ${CLUSTER} ${LAUNCH_DIR} ${TEST_NAME} >> ${LOGFILE}

# clean up
rm total_time.txt

# push to git
git add results/timings_${CLUSTER}_${TEST_NAME}.txt
git commit -m 'update benchmark results ${CLUSTER} ${TEST_NAME}'
#git push
JOBSCRIPT
