#!/bin/bash

cat <<JOBSCRIPT > "$OUTPUT_FILE"
#!/bin/bash -l
#SBATCH --job-name=${JOB_NAME}
#SBATCH --account=${CLUSTER_ALLOCATION_ID}
#SBATCH --partition=${CLUSTER_PARTITION}
#SBATCH --nodes=${NBNODES}
#SBATCH --ntasks-per-node=${CLUSTER_CORES_PER_NODE}
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --time=${TEST_TIME}
#SBATCH --output=slurm_%j.out
#SBATCH --error=slurm_%j.err

export DATE=\$(date +%F_%Hh%M)

JOBSCRIPT
