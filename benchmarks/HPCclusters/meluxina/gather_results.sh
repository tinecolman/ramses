# ------------------- Construct job script ------------

JOB_FILE=io_${TEST_NAME}.sh

echo "#!/bin/bash -l" > ${JOB_FILE}

# SLURM job settings
echo "#SBATCH --job-name=io-${TEST_NAME}" >> ${JOB_FILE}
echo "#SBATCH --account=${CLUSTER_ACCOUNT}" >> ${JOB_FILE}
echo "#SBATCH --partition=${CLUSTER_PARTITION}" >> ${JOB_FILE}
echo "#SBATCH --qos=${CLUSTER_QOS}" >> ${JOB_FILE}
echo "#SBATCH --nodes=1" >> ${JOB_FILE}
echo "#SBATCH --ntasks-per-node=1" >> ${JOB_FILE}
echo "#SBATCH --cpus-per-task=1" >> ${JOB_FILE}
echo "#SBATCH --time=00:05:00" >> ${JOB_FILE}
echo "#SBATCH --output=slurm_results.out" >> ${JOB_FILE}
echo "#SBATCH --error=slurm_results.err" >> ${JOB_FILE}

echo "" >> ${JOB_FILE}

# modules
echo "module load ${MODULE_PYTHON}" >> ${JOB_FILE}

echo "" >> ${JOB_FILE}

# run command
echo "python io_timings.py ${CLUSTER} ${LAUNCH_DIR} ${TEST_NAME}" >> ${JOB_FILE}
