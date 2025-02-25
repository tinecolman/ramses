#!/bin/bash

# Define output file
OUTPUT_FILE="io_$TEST_NAME.sh"

# ------------------- Construct job script ------------

cat <<JOBSCRIPT > "$OUTPUT_FILE"
#!/bin/bash -l
#SBATCH --job-name=${TEST_NAME}
#SBATCH --account=${CLUSTER_ALLOCATION_ID}
#SBATCH --partition=${CLUSTER_PARTITION}
#SBATCH --qos=${CLUSTER_QOS}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-core=1
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --time=00:05:00
#SBATCH --output=slurm_$TEST_NAME.out
#SBATCH --error=slurm_$TEST_NAME.err

module load ${MODULE_PYTHON}

python io_timings.py ${CLUSTER} ${LAUNCH_DIR} ${TEST_NAME} >> ${LOGFILE}

# push to git
git add results/timings_${CLUSTER}_${TEST_NAME}.txt
git commit -m 'update benchmark results ${CLUSTER} ${TEST_NAME}'
git push

JOBSCRIPT
