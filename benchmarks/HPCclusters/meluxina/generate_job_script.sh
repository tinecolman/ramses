# ------------------- Construct job script ------------

echo "#!/bin/bash -l" > job.sh

# SLURM job settings
echo "#SBATCH --job-name=${TEST_NAME}" >> job.sh
echo "#SBATCH --account=${CLUSTER_ACCOUNT}" >> job.sh
echo "#SBATCH --partition=${CLUSTER_PARTITION}" >> job.sh
echo "#SBATCH --qos=${CLUSTER_QOS}" >> job.sh
echo "#SBATCH --nodes=${NBNODES}" >> job.sh
echo "#SBATCH --ntasks-per-node=$(( $CLUSTER_CORES_PER_NODE/$NBTHREADS ))" >> job.sh
echo "#SBATCH --cpus-per-task=${NBTHREADS}" >> job.sh
echo "#SBATCH --threads-per-core=1" >> job.sh
echo "#SBATCH --exclusive" >> job.sh
echo "#SBATCH --time=${TEST_TIME}" >> job.sh
echo "#SBATCH --output=slurm_%j.out" >> job.sh
echo "#SBATCH --error=slurm_%j.err" >> job.sh

echo "" >> job.sh

# modules
echo "module load ${MODULE_COMPILER}" >> job.sh
echo "module load ${MODULE_MPI}" >> job.sh

echo "" >> job.sh
echo 'export DATE=`date +%F_%Hh%M`' >> job.sh
echo "" >> job.sh

# run command
echo "srun ./${TEST_EXECUTABLE} ${TEST_NAMELIST} > run_\${DATE}_\${SLURM_JOBID}.log" >> job.sh
