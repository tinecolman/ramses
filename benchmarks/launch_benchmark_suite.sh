#!/bin/bash
#######################################################################
#
# Script to run the RAMSES performance benchmarks
#
# Usage:
#   ./launch_benchmark_suite.sh
#
# Options:
#   - specify on which cluster you are
#       ./launch_benchmark_suite.sh -c meluxina
#   - select setup
#       ./launch_benchmark_suite.sh -t 2
#   - also do weak scaling
#       ./launch_benchmark_suite.sh -w weak
#   - set maximum number of nodes (default is 32)
#       ./launch_benchmark_suite.sh -n 40
#   - select a specific branch or commit to test
#       ./launch_benchmark_suite.sh -h ab01cd23
#       ./launch_benchmark_suite.sh -h mybranch
#   - run with openmp (code will be compiled with OpenMP!)
#       ./launch_benchmark_suite.sh -m "1 2 4 8 16"
#
#######################################################################

#######################################################################
# Determine the parameters for running the performance tests
#######################################################################
# TODO make this script work without having to submit job scripts.

HASH="current"
NODESMAX=32
NODELIST="0"
CLUSTER=zapus;
CLUSTER_ALLOCATION_ID="none"
SELECTTEST=false;
WEAKSCALING=false
DELDATA=true;
OPENMP=0;
OMP_THREAD_LIST="0"
ITERS=3
while getopts "c:a:h:t:wn:dm:l:i:" OPTION; do
   case $OPTION in
      c)
         CLUSTER=$OPTARG;
      ;;
      a)
         CLUSTER_ALLOCATION_ID=$OPTARG;
      ;;
      h)
         HASH=$OPTARG;
      ;;
      t)
         SELECTTEST=true;
         TESTNUMBER=$OPTARG;
      ;;
      w)
         WEAKSCALING=true;
      ;;
      n)
         NODESMAX=$OPTARG;
      ;;
      d)
         DELDATA=false;
      ;;
      m)
         OPENMP=1;
         OMP_THREAD_LIST=($OPTARG);  # Convert input string into an array
      ;;
      l)
         NODELIST=($OPTARG);
      ;;
      i)
         ITERS=$OPTARG;
      ;;
   esac
done

#######################################################################
# Useful definitions
#######################################################################

RAMSES_BENCHMARK_DIR=$(pwd);                      # The benchmark suite directory
EXECNAME="benchmark_exe_";
BEFORETEST="before-test.sh";
AFTERTEST="after-test.sh";
CLUSTER_INFO="${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/cluster_info.sh"
UPDATECODE="${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/update-code.sh"
COMPILECODE="${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/compile_code.sh"
MODULES="${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/modules.sh"

DATE=`date +%F`
LOGFILE="${RAMSES_BENCHMARK_DIR}/benchmark_suite.log";
line="--------------------------------------------";

# begin logfile
echo > $LOGFILE;

#######################################################################
# Setup code repository
#######################################################################

if [[ "$HASH" == "current" ]]; then
   # By default, we are running the benchmark with the current version of the code.
   # This will be the case when using the script from the CI/CD.
   RAMSES_BIN_DIR="${RAMSES_BENCHMARK_DIR}/../bin";

else
   set -e
   # If a commit or branch is given as input, the script will:
   #  - create a temporary copy of the code
   #  - checkout the correct branch/commit there
   #  - set the path to the new bin, so that the compilation is done in this copied version
   # needs internet access
   #git fetch origin >> $LOGFILE
   RAMSES_ORIG_DIR=$(dirname "${RAMSES_BENCHMARK_DIR}")
   RAMSES_TEMP_DIR="${RAMSES_ORIG_DIR}_temp_${HASH}"
   echo "Creating temporary ramses copy..." | tee -a $LOGFILE
   rsync -a $RAMSES_ORIG_DIR/ $RAMSES_TEMP_DIR --exclude benchmarks >> $LOGFILE
   cd "$RAMSES_TEMP_DIR" || exit 1

   # make sure the copy is clean
   git stash --include-untracked
   git stash drop

   git checkout "$HASH" | tee -a $LOGFILE
   #git merge  >> $LOGFILE
   set +e

   RAMSES_BIN_DIR="${RAMSES_TEMP_DIR}/bin";
fi

# get info of repo
cd $RAMSES_BIN_DIR
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT=$(git rev-parse --short HEAD)
COMMIT_DATE=$(git show --no-patch --format=%ci ${COMMIT})
GIT_URL=$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//g')
GIT_URL=${GIT_URL:0:$((${#GIT_URL}-4))}
cd $RAMSES_BENCHMARK_DIR

# Welcome message
echo "#################################################" | tee -a $LOGFILE
echo "#    Launching RAMSES performance benchmarks    #" | tee -a $LOGFILE
echo "#################################################" | tee -a $LOGFILE
echo "Repository url: ${GIT_URL}" >> $LOGFILE
echo "Branch: ${BRANCH}" >> $LOGFILE
echo "Commit hash: ${COMMIT}" >> $LOGFILE
echo $line >> $LOGFILE

#######################################################################
# Select project allocation to run on, if not given by user
#######################################################################

if [[ "$CLUSTER_ALLOCATION_ID" == "none" ]]; then

   # Get the list of project IDs for the current user (works only for slurm)
   #   - ignoring headers (tail -n +3)
   #   - taking care of long account names (format=Account%-40)
   #   - removing duplicates (sort -u)
   MY_PROJECTS=$(sacctmgr show associations user=$USER format=Account%-40 | tail -n +3 | awk '{print $1}' | sort -u)

   # Count the number of projects
   NUM_PROJECTS=$(echo "$MY_PROJECTS" | wc -l)

   # Process the number of projects
   if [[ $NUM_PROJECTS -eq 1 ]]; then
      CLUSTER_ALLOCATION_ID=$(echo "$MY_PROJECTS" | xargs)
      echo "Automatically selected allocation ID: $CLUSTER_ALLOCATION_ID" | tee -a $LOGFILE

   elif [[ $NUM_PROJECTS -gt 1 ]]; then
      # if multiple projects are found, present the user with a list to select from
      echo "Multiple projects found. Please select one:"
      select CLUSTER_ALLOCATION_ID in $MY_PROJECTS; do
         if [[ -n "$CLUSTER_ALLOCATION_ID" ]]; then
            CLUSTER_ALLOCATION_ID=$(echo "$CLUSTER_ALLOCATION_ID" | xargs)
            echo "You selected allocation ID: $CLUSTER_ALLOCATION_ID" | tee -a $LOGFILE
            break
         else
            echo "Invalid selection, please try again."
         fi
      done

   else
      echo "No valid allocation ID found." | tee -a $LOGFILE
      exit 1
   fi

fi

#######################################################################
# Set cluster parameters 
#######################################################################

# TODO make MPIF90 more elegant
MPIF90="mpif90 -march=native -flto -fwhole-program"
source ${CLUSTER_INFO}

# create directory on scratch
BENCHMARK_DIR=$CLUSTER_SCRATCH/benchmark_${BRANCH}_${COMMIT}
mkdir -p ${BENCHMARK_DIR} >> $LOGFILE 2>&1;

#######################################################################
# Generate list of tests by scanning directory
#######################################################################

# list subdirectories of setups base directory, which contain individual tests
testlist="setups/*";

# Count number of tests
testname=( $testlist );
ntests_all=${#testname[@]};
all_tests_ok=true;

if $SELECTTEST ; then
   # Split test selection with commas
   s1=$(echo $TESTNUMBER | sed 's/,/ /g');
   testsegs=( $s1 );
   nseg=${#testsegs[@]};

   ntests=0;
   # Search for dashes in individual segments
   for ((n=0;n<$nseg;n++)); do
      # No dash, just include test in list
      if [ ${testsegs[n]} -gt 0 ] && [ ${testsegs[n]} -le ${ntests_all} ] ; then
         testnum[${ntests}]=$((${testsegs[n]} - 1));
         ntests=$((ntests + 1));
      else
         echo "Selected test ${testsegs[n]} does not exist! Ignoring test" | tee -a $LOGFILE;
      fi
   done

else
   # Include all tests by default
   for ((n=0;n<$ntests_all;n++)); do
      testnum[n]=$n;
   done
   ntests=$ntests_all
fi

# Write list of tests
echo "Will launch the following benchmarks:" | tee -a $LOGFILE;
for ((i=0;i<$ntests;i++)); do
   n=${testnum[i]};
   j=$(($n + 1));
   if [ $j -lt 10 ] ; then
      echo " [ ${j}] ${testname[n]}" | tee -a $LOGFILE;
   else
      echo " [${j}] ${testname[n]}" | tee -a $LOGFILE;
   fi
done
echo $line | tee -a $LOGFILE;

# setup number of nodes array
if [[ "$NODELIST" == "0" ]] ; then
   BENCHMARK_NBNODES_LIST=(1)
   n=2
   while [ ${n} -le ${NODESMAX} ]; do
      BENCHMARK_NBNODES_LIST+=(${n})
      n=$((n*2))
   done
else
   for n in "${NODELIST[@]}"; do
      BENCHMARK_NBNODES_LIST+=(${n})
   done
fi


#######################################################################
# Loop through all tests
#######################################################################

for ((i=0;i<$ntests;i++)); do

   cd ${BENCHMARK_DIR}

   # Get test number
   n=${testnum[i]};
   ip1=$(($i + 1));

   # Get raw test name for namelist, pdf and tex files
   nslash=$(grep -o "/" <<< "${testname[n]}" | wc -l);
   if [ $nslash -gt 0 ] ; then
      np1=$(($nslash + 1));
      rawname[i]=$(echo ${testname[n]} | cut -d '/' -f$np1);
   else
      rawname[i]=${testname[n]};
   fi
   TEST_NAME=${rawname[i]}

   echo "Test ${ip1}/${ntests}: ${TEST_NAME}" | tee -a $LOGFILE;

   # Read test configuration file
   FLAGS=$(grep FLAGS ${RAMSES_BENCHMARK_DIR}/setups/${TEST_NAME}/config.txt | cut -d ':' -f2);

   # load modules
   source $MODULES >> $LOGFILE 2>&1

   # Recompile source code
   NBNODES=1
   NTASKS_PER_NODE=1
   CPUS_PER_TASK=1
   set -e
   MAKESTRING="make EXEC=${EXECNAME} COMPILER=${COMPILER_FLAVOR} MPIF90=\"${MPIF90}\" MPI=1 OPENMP=${OPENMP} ${FLAGS}";
   TEST_EXECUTABLE=${EXECNAME}3d
   cd ${RAMSES_BIN_DIR};
   make clean >> $LOGFILE 2>&1;
   if [ -f ${COMPILECODE} ]; then
      # submit a job script to compile the code
      source ${COMPILECODE}
      compile_job_id=$(sbatch compile_job.sh | awk '{print $4}')
      echo "Compile job submitted with Job ID: $compile_job_id"
      echo "Waiting for compile job to finish..."
      # Poll the job status and wait until it's completed
      while true; do
         job_status=$(sacct --jobs=$compile_job_id --noheader --format=JobID,State | awk -v job_id="$compile_job_id" '$1 == job_id {print $2}')
         if [[ "$job_status" == "COMPLETED" ]]; then
            echo "Compile job completed successfully."
            break
         elif [[ "$job_status" == "FAILED" || "$job_status" == "CANCELLED" ]]; then
            echo "Compile job failed or was cancelled. Exiting..."
            exit 1
         fi
         # Sleep for a while before checking the status again
         sleep 15
      done
   else
      echo "Compiling source" | tee -a $LOGFILE;
      $MAKESTRING >> $LOGFILE 2>&1;
   fi
   set +e

   # check if stuff needs to be downloaded
   #if [ -f ${BEFORETEST} ]; then
   #   ${SHELL} ${BEFORETEST} >> $LOGFILE 2>&1;
   #fi

   # create subdirectory for setup
   LAUNCH_DIR=$BENCHMARK_DIR/${TEST_NAME}
   mkdir -p ${LAUNCH_DIR} >> $LOGFILE 2>&1;
   cd ${LAUNCH_DIR}

   # load scaling configuration
   source ${RAMSES_BENCHMARK_DIR}/${testname[n]}/scaling_config.sh
   NODES_LIST=()
   RESO_LIST=()
   for NBNODES in "${BENCHMARK_NBNODES_LIST[@]}"; do
      # Add strong scaling configs
      NODES_LIST+=("$NBNODES")
      RESO_LIST+=("$STRONG_SCALING_RESO")
   done
   if ${WEAKSCALING}; then
      # Add weak scaling cases if enabled
      nconfigs=${#WEAK_SCALING_RESO[@]}
      for ((w=0; w<nconfigs; w++)); do
         NODES_LIST+=("${WEAK_SCALING_NNODES[w]}")
         RESO_LIST+=("${WEAK_SCALING_RESO[w]}")
      done
   fi

   # move ICs to scratch if needed
   #TODO
   # check if there are IC required
   # check if ICs are already on scratch
   # copy ICs to scratch if they are not present

   JOB_NAME=$TEST_NAME

   # Loop over configurations
   for ((c=0; c<${#NODES_LIST[@]}; c++)); do
      NBNODES=${NODES_LIST[c]}
      RESO=${RESO_LIST[c]}

      for OMP_THREADS in "${OMP_THREAD_LIST[@]}"; do

         # set the number of MPI processes and OpenMP threads
         if (( $OMP_THREADS != 0 && $CLUSTER_CORES_PER_NODE % OMP_THREADS != 0 )); then
            echo "Skipping OMP_THREADS=${OMP_THREADS} (not divisible into ${CLUSTER_CORES_PER_NODE} cores)."
            continue
         fi
         if (( $OMP_THREADS != 0 )); then
            NTASKS_PER_NODE=$(($CLUSTER_CORES_PER_NODE / $OMP_THREADS))
            CPUS_PER_TASK=$OMP_THREADS
         else
            NTASKS_PER_NODE=$CLUSTER_CORES_PER_NODE
            CPUS_PER_TASK=1
         fi
         NUMPROCS=$(($NBNODES * $NTASKS_PER_NODE)) 

         # make subdirectory
         RUN_DIR=nodes${NBNODES}_reso${RESO}_omp${OMP_THREADS}
         mkdir -p ${RUN_DIR} >> $LOGFILE 2>&1;
         cd ${RUN_DIR}

         # Copy executable and input file   
         cp ${RAMSES_BIN_DIR}/${EXECNAME}3d .
         TEST_NAMELIST=${TEST_NAME}_${RESO}.nml
         cp ${RAMSES_BENCHMARK_DIR}/setups/${TEST_NAME}/${TEST_NAMELIST} .

         # create job script by combining job params, modules and run command
         OUTPUT_FILE="job.sh"
         COMMANDSTRING="$(eval echo ${RUN_COMMAND}) ./${TEST_EXECUTABLE} ${TEST_NAMELIST} > run_\${DATE}_\${SLURM_JOBID}.log"
         source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/job_script_params.sh
         # add the date, which is used to add the execution timestamp to the name of the log-file of the simulation.
         echo "export DATE=\$(date +%F_%Hh%M)" >> "$OUTPUT_FILE"
         if (( $OMP_THREADS != 0 )); then
            echo "export OMP_NUM_THREADS=$OMP_THREADS" >> "$OUTPUT_FILE"
            echo "export OMP_PLACES=cores" >> "$OUTPUT_FILE"
            echo "export OMP_PROC_BIND=true" >> "$OUTPUT_FILE"
         fi
         cat $MODULES >> $OUTPUT_FILE
         echo "" >> "$OUTPUT_FILE"
         echo "$COMMANDSTRING" >> "$OUTPUT_FILE"

         # launch job multiple times
         for iter in $(seq $ITERS); do
            SUBMIT_MESSAGE=$(sbatch job.sh)
            STRINGARRAY=($SUBMIT_MESSAGE)
            JOB_ID=${STRINGARRAY[-1]}
            echo "Launched benchmark ${TEST_NAME} on ${NBNODES} nodes with ${OMP_THREADS} threads [JOB ID ${JOB_ID}]" | tee -a $LOGFILE;
         done
         cd ..
      done
   done

   # launch dependency job to gather results
   #cd ${RAMSES_BENCHMARK_DIR}
   #OUTPUT_FILE="io_${TEST_NAME}.sh"
   #NBNODES=1
   #NTASKS_PER_NODE=1
   #CPUS_PER_TASK=1
   #JOB_NAME=io-${TEST_NAME}
   #source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/job_script_params.sh
   #source io_job.sh
   #DEPS=$(squeue --noheader --format %i --name ${TEST_NAME} | paste -sd,)
   #sbatch --dependency=${DEPS} $OUTPUT_FILE

done

#######################################################################
# Clean up
#######################################################################
if ${DELDATA} ; then
   for ((i=0;i<$ntests;i++)); do
      n=${testnum[i]};
      cd ${RAMSES_BENCHMARK_DIR}/${testname[n]};
      if [ -f ${AFTERTEST} ]; then
         ${SHELL} ${AFTERTEST};
      fi
   done
   cd ${RAMSES_BIN_DIR};
   make clean >> $LOGFILE 2>&1;
   rm -f ${EXECNAME}*d;
   if [[ "$HASH" != "current" ]]; then
      rm -rf "$RAMSES_TEMP_DIR"
   fi
fi

