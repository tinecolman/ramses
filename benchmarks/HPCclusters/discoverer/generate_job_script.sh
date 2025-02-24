#!/bin/bash

# Define output file
OUTPUT_FILE="job.sh"

# ------------------- Construct job script ------------

cat <<JOBSCRIPT > "$OUTPUT_FILE"

#!/bin/bash -l
#SBATCH --job-name=${TEST_NAME}
#SBATCH --account=${CLUSTER_ALLOCATION_ID}
#SBATCH --partition=${CLUSTER_PARTITION}
#SBATCH --qos=${CLUSTER_QOS}
#SBATCH --nodes=${NBNODES}
#SBATCH --ntasks-per-node=${CLUSTER_CORES_PER_NODE}
#SBATCH --ntasks-per-core=1
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive
#SBATCH --mem 251G
#SBATCH --time=${TEST_TIME}
#SBATCH --output=slurm_%j.out
#SBATCH --error=slurm_%j.err

module load ${MODULE_COMPILER}
module load ${MODULE_MPI}

export DATE=`date +%F_%Hh%M`

srun ./${TEST_EXECUTABLE} ${TEST_NAMELIST} > run_\${DATE}_\${SLURM_JOBID}.log

JOBSCRIPT
