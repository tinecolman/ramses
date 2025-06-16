#!/bin/bash

# Define output file
OUTPUT_FILE="compile_job.sh"

# set jobscript params
NBNODES=1
NTASKS_PER_NODE=1
JOB_NAME=compile
TEST_TIME="00:05:00"
source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/job_script_params.sh

# append modules to load
cat $MODULES >> $OUTPUT_FILE

# add compile command
echo "$MAKESTRING >> $LOGFILE 2>&1;"  >> $OUTPUT_FILE
