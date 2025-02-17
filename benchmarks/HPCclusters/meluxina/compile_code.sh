# ------------------- Construct compile job script ------------
echo "#!/bin/bash -l" > compile_job.slm
# SLURM job settings
echo "#SBATCH --job-name=compile" >> compile_job.slm
echo "#SBATCH --account=${CLUSTER_ACCOUNT}" >> compile_job.slm
echo "#SBATCH --partition=${CLUSTER_PARTITION}" >> compile_job.slm
echo "#SBATCH --qos=${CLUSTER_QOS}" >> compile_job.slm
echo "#SBATCH --nodes=1" >> compile_job.slm
echo "#SBATCH --ntasks-per-node=1" >> compile_job.slm
echo "#SBATCH --cpus-per-task=1" >> compile_job.slm
echo "#SBATCH --threads-per-core=1" >> compile_job.slm
echo "#SBATCH --time=00:05:00" >> compile_job.slm
echo "#SBATCH --output=compile.out" >> compile_job.slm
echo "#SBATCH --error=compile.err" >> compile_job.slm
echo "" >> compile_job.slm
# modules
echo "module load ${MODULE_COMPILER}" >> compile_job.slm
echo "module load ${MODULE_MPI}" >> compile_job.slm
# run command
echo "$MAKESTRING >> $LOGFILE 2>&1;" >> compile_job.slm

# launch script
sbatch compile_job.slm

# wait for compilation to finish
sleep 90
