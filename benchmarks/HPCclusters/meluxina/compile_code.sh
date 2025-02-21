#!/bin/bash

# Define output file
OUTPUT_FILE="compile_job.sh"

# ------------------- Construct compile job script ------------

cat <<COMPILEJOB > "$OUTPUT_FILE"
#!/bin/bash -l
#SBATCH --job-name=compile
#SBATCH --account=${CLUSTER_ALLOCATION_ID}
#SBATCH --partition=${CLUSTER_PARTITION}
#SBATCH --qos=${CLUSTER_QOS}
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --time=00:05:00
#SBATCH --output=compile.out
#SBATCH --error=compile.err

module load ${MODULE_COMPILER}
module load ${MODULE_MPI}

$MAKESTRING >> $LOGFILE 2>&1;
COMPILEJOB
