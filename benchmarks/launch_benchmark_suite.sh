#!/bin/bash
#######################################################################
#
# Script to run the RAMSES performance tests
#
# Usage:
#   ./launch_benchmark_suite.sh
#
# Options:
#   - Specify on which cluster you are
#       ./launch_benchmark_suite.sh -c meluxina
#   - Select setup
#       ./launch_benchmark_suite.sh -t 2
#   - Select weak or strong scaling
#       ./launch_benchmark_suite.sh -s weak
#   - Select maximum number of nodes
#       ./launch_benchmark_suite.sh -n 40
#
#######################################################################

#######################################################################
# Determine the parameters for running the performance tests
#######################################################################
NODESMAX=64
CLUSTER=zapus;
SELECTTEST=false;
STRONGSCALING=true;
WEAKSCALING=false
VERBOSE=false;
DELDATA=true;
BRANCH=performance_tests;
while getopts "c:t:wn:dv" OPTION; do
   case $OPTION in
      c)
         CLUSTER=$OPTARG;
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
      v)
         VERBOSE=true;
      ;;
   esac
done


#######################################################################
# Setup paths and commands
#######################################################################

# useful definitions
RAMSES_BENCHMARK_DIR=$(pwd);                      # The benchmark suite directory
BIN_DIRECTORY="${RAMSES_BENCHMARK_DIR}/../bin";   # The bin directory
RETURN_TO_BIN="cd ${BIN_DIRECTORY}";
EXECNAME="benchmark_exe_";
BEFORETEST="before-test.sh";
AFTERTEST="after-test.sh";
DATE=`date +%F`
LOGFILE="${RAMSES_BENCHMARK_DIR}/benchmark_suite.log";
line="--------------------------------------------";

# begin logfile
echo > $LOGFILE;

# set cluster info
source HPCclusters/${CLUSTER}/set_cluster_info.sh
UPDATECODE="HPCclusters/${CLUSTER}/update-code.sh"
COMPILECODE="HPCclusters/${CLUSTER}compile_code.sh"

# check if we are on the correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Benchmarking branch ${CURRENT_BRANCH}"

# get the latest version of the code
#git checkout ${BRANCH} >> $LOGFILE 2>&1;
if [ -f ${UPDATECODE} ]; then
   # special attention needed to pull the code
   ${SHELL} ${UPDATECODE} 2>&1 | tee -a $LOGFILE;
else
   git pull >> $LOGFILE 2>&1;
fi
THIS_COMMIT=$(git rev-parse --short HEAD)
GIT_URL=$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//g');
GIT_URL=${GIT_URL:0:$((${#GIT_URL}-4))};

# create directory on scratch
BENCHMARK_DIR=$CLUSTER_SCRATCH/benchmark_${BRANCH}_${THIS_COMMIT}_${DATE}
mkdir ${BENCHMARK_DIR} >> $LOGFILE 2>&1;


#######################################################################
# Welcome message
#######################################################################

echo "############################################" | tee -a $LOGFILE;
echo "#    Launching RAMSES performance tests    #" | tee -a $LOGFILE;
echo "############################################" | tee -a $LOGFILE;
echo "Repository url: ${GIT_URL}" >> $LOGFILE;
echo "Commit hash: ${THIS_COMMIT}" >> $LOGFILE;
echo $line >> $LOGFILE;


#######################################################################
# Generate list of tests from scanning directory
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
echo "Will perform the following tests:" | tee -a $LOGFILE;
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
BENCHMARK_NBNODES_LIST=(1)
n=2
while [ ${n} -le ${NODESMAX} ]; do
   BENCHMARK_NBNODES_LIST+=(${n})
   n=$((n*2))
done

#######################################################################
# Setup 
#######################################################################


#######################################################################
# Loop through all tests
#######################################################################
for ((i=0;i<$ntests;i++)); do

   cd ${BENCHMARK_DIR}

   # Get test number
   n=${testnum[i]};
   ip1=$(($i + 1));
   echo "Test ${ip1}/${ntests}: ${testname[n]}" | tee -a $LOGFILE;

   # Get raw test name for namelist, pdf and tex files
   nslash=$(grep -o "/" <<< "${testname[n]}" | wc -l);
   if [ $nslash -gt 0 ] ; then
      np1=$(($nslash + 1));
      rawname[i]=$(echo ${testname[n]} | cut -d '/' -f$np1);
   else
      rawname[i]=${testname[n]};
   fi

   # Read test configuration file
   FLAGS=$(grep FLAGS ${RAMSES_BENCHMARK_DIR}/${testname[n]}/config.txt | cut -d ':' -f2);

   # Recompile source code
   MAKESTRING="make EXEC=${EXECNAME} COMPILER=${COMPILER_FLAVOR} MPI=1 ${FLAGS}";
   $RETURN_TO_BIN;
   make clean >> $LOGFILE 2>&1;
   echo "Compiling source" | tee -a $LOGFILE;
   if [ -f ${COMPILECODE} ]; then
      # special attention needed for compilation
      source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/${COMPILECODE}
   else
      $MAKESTRING >> $LOGFILE 2>&1;
   fi
   # TODO catch compilation error and abort

   # load scaling configuration
   source ${RAMSES_BENCHMARK_DIR}/${testname[n]}/scaling_config.sh

   # check if stuff needs to be downloaded
   #if [ -f ${BEFORETEST} ]; then
   #   ${SHELL} ${BEFORETEST} >> $LOGFILE 2>&1;
   #fi

   # ------- STRONG SCALING -----------

   # create subdirectory for setup
   LAUNCH_DIR=$CLUSTER_SCRATCH/benchmark_${BRANCH}_${THIS_COMMIT}_${DATE}/${rawname[i]}
   mkdir ${LAUNCH_DIR} >> $LOGFILE 2>&1;
   cd ${LAUNCH_DIR}

   # create job scripts for each node configuration and launch jobs to queue
   for NBNODES in ${BENCHMARK_NBNODES_LIST[@]}; do
      # make subdirectory
      mkdir nodes${NBNODES}_reso${STRONG_SCALING_RESO} >> $LOGFILE 2>&1;
      cd nodes${NBNODES}_reso${STRONG_SCALING_RESO}
      # add executable
      cp ${BIN_DIRECTORY}/${EXECNAME}3d .
      # add input file
      cp ${RAMSES_BENCHMARK_DIR}/${testname[n]}/${rawname[i]}_${STRONG_SCALING_RESO}.nml .
      # create job script
      TEST_NAME=${rawname[i]}
      TEST_EXECUTABLE=${EXECNAME}3d
      TEST_NAMELIST=${rawname[i]}_${STRONG_SCALING_RESO}.nml
      source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/generate_job_script.sh
      #launch job
      for iter in $(seq 3); do
         SUBMIT_MESSAGE=$(sbatch job.sh)
         STRINGARRAY=($SUBMIT_MESSAGE)
         JOB_ID=${STRINGARRAY[-1]}
         echo "Launched benchmark ${rawname[i]} on ${NBNODES} nodes [JOB ID ${JOB_ID}]" | tee -a $LOGFILE;
      done
      cd ..
   done

   # launch additional weak scaling jobs
   if ${WEAKSCALING}; then
      nconfigs=${#WEAK_SCALING_RESO[@]};
      for ((w=0;w<$nconfigs;w++)); do
         # create new subdir for different resolution
         LAUNCH_DIR=$CLUSTER_SCRATCH/benchmark_${BRANCH}_${THIS_COMMIT}_${DATE}/${rawname[i]}_${WEAK_SCALING_RESO[w]}
         mkdir ${LAUNCH_DIR}
         cd ${LAUNCH_DIR}
         mkdir nodes${WEAK_SCALING_NNODES[w]}
         cd nodes${WEAK_SCALING_NNODES[w]}
         cp ${BIN_DIRECTORY}/${EXECNAME}3d .
         cp ${RAMSES_BENCHMARK_DIR}/${testname[n]}/${rawname[i]}_${WEAK_SCALING_RESO[w]}.nml .
         # create job script
         source ${RAMSES_BENCHMARK_DIR}/HPCclusters/${CLUSTER}/generate_job_script.sh
         #launch job
         JOB_ID=1
         #$(sbatch job.sh)
         echo "Launched benchmark ${rawname[i]} on ${NBNODES} nodes [${JOB_ID}]" | tee -a $LOGFILE;
         cd ..
      done
   fi

   # launch dependency job to gather results
   cd ${RAMSES_BENCHMARK_DIR}
   source HPCclusters/${CLUSTER}/gather_results.sh
   DEPS=$(squeue --noheader --format %i --name ${TEST_NAME} | paste -sd,)
   sbatch --dependency=${DEPS} io_${TEST_NAME}.sh


done

#######################################################################
# Clean up
#######################################################################
if ${DELDATA} ; then
   for ((i=0;i<$ntests;i++)); do
      n=${testnum[i]};
      cd ${RAMSES_BENCHMARK_DIR}/${testname[n]};
      $DELETE_RESULTS;
      if [ -f ${AFTERTEST} ]; then
         ${SHELL} ${AFTERTEST};
      fi
   done
   $RETURN_TO_BIN;
   if $VERBOSE ; then
      make clean 2>&1 | tee -a $LOGFILE;
   else
      make clean >> $LOGFILE 2>&1;
   fi
   rm -f ${EXECNAME}*d;
fi

