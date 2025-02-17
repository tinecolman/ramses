'''
This script analyses the data produced by the benchmark runs.
The input is the test case name.

Several plots are produced:
  - strong_scaling: shows the speedup in function of the number of nodes.
                    The datapoint show an average of the execution time,
                    while the error bars indicate the variation between timings.
                    Previous measurements are shown in differently colored lines
                    using a colormap. The legend indicates the data of the benchmark.
  - execution_time: show the execution time in function of the benchmark date.
                    The datapoint show an average of the execution time,
                    while the error bars indicate the variation between timings.
                    A curve is drawn for each number of nodes used in the strong scaling.
  - weak_scaling: Shows the parallel efficiency as a function of nodes, keeping the
                  the problem size per node constant.
                  The datapoint show an average of the execution time,
                  while the error bars indicate the variation between timings.
                  Previous measurements are shown in differently colored lines
                  using a colormap. The legend indicates the data of the benchmark.

The processed data is stored in text files, which are uploaded to the git.
The name of the file is: timings_<system>_<testname>_<short commit hash>_<benchmark date>.txt
The file contains a table with several columns:
# resolution, number of nodes, total execution time
A header is written at the top. Possibilty to extend to store individual timers.
'''

import subprocess
import numpy as np
import os
import re
from matplotlib import pyplot as plt
import matplotlib.colors as colorsx
import matplotlib.cm as cmx

''' Get average time and error bars from total time printed in log files, for a certain resolution-node config '''
def get_timings_total(run_dir):
    # grep total time from logfiles
    subprocess.call("grep --no-filename 'Total elapsed time' {}/*.log".format(run_dir) +" | awk '{print $4}' > total_time.txt", shell=True)
    total_time=np.loadtxt('total_time.txt', unpack=True)
    total_time=np.array([total_time]).flatten()
    if len(total_time)>0:
        # take the average and determine the error
        time = np.sum(total_time) / len(total_time)
        error_min = time-np.min(total_time)
        error_max = np.max(total_time)-time
    else:
        time = np.nan
        error_min=0
        error_max=0
    return time, error_min, error_max


''' Construct filename where timings are stored.
'''
def get_test_filename(test_name):
    return "timings_" + test_name

''' Append new data to file '''
def update_history(file_name):
    return


''' Load previous data '''
def load_history(file_name):
    return

'''  '''
def plot_strong_scaling(benchmark_dir, reso_strong, nodes_strong):

    # gather data from log files
    times, errors_min, errors_max = [], [], []
    for nnodes in nodes_strong:
        subdir_name = 'nodes'+str(nnodes)+'_reso'+str(reso_strong)
        time, error_min, error_max = get_timings_total(benchmark_dir+'/'+subdir_name)
        times.append(time)
        errors_min.append(error_min)
        errors_max.append(error_max)
    speedups = times[0]*nnodes[0]/times
    #TODO convert time errors to speedup errors
    # write results to file

    # make strong scaling plot
    plt.figure(figsize=[5,4])
    # add previous results
    #TODO
    # add latest results
    plt.scatter(nodes_strong, speedups, color='black', label='latest')
    plt.plot([1,max(nodes_strong)], [1,max(nodes_strong)], ls=':', color='black')
    
    plt.xlabel('number of nodes')
    plt.ylabel('speedup')
    plt.xscale('log')
    plt.yscale('log')
    plt.legend()
    plt.savefig('strong_scaling.png', bbox_inches='tight', dpi=200)
    plt.close()


'''  '''
def plot_execution_time(benchmark_dir_list, reso_strong, nodes_strong):

    dates = []
    times = {}
    errors_min = {}
    errors_max = {}
    for n in nodes_strong:
        times[n] = []
        errors_min[n] = []
        errors_max[n] = []

    for benchmark_dir in benchmark_dir_list:
        #dates.append(benchmark_dir[-16:-6])
        dates.append(benchmark_dir[-25:-17]+'\n'+benchmark_dir[-16:-6])
        # gather data from log files
        for n in nodes_strong:
            subdir_name = 'nodes'+str(n)+'_reso'+str(reso_strong)
            time, error_min, error_max = get_timings_total(benchmark_dir+'/'+subdir_name)
            times[n].append(time)
            errors_min[n].append(error_min)
            errors_max[n].append(error_max)

    # create colors
    cmap = cmx.get_cmap('managua')
    cNorm  = colorsx.Normalize(vmin=0, vmax=len(nodes_strong)-1)
    colorVals =  []
    for val in range(len(nodes_strong)):
        colorVals.append(cmap(cNorm(val)))

    # plot
    plt.figure(figsize=[5,4])
    for i, c in zip(nodes_strong,colorVals):
        plt.errorbar(dates, times[i], yerr=[errors_min[i],errors_max[i]], fmt='o', markersize=5,
                     label=str(i)+' nodes', color=c)
        # plot a line from the last point to make comparison easier
        plt.plot([dates[0],dates[-1]], [times[i][-1],times[i][-1]], ls=':', lw=1.3, color=c)

    plt.ylabel('execution time [s]')
    plt.yscale('log')
    plt.legend()
    plt.savefig('execution_time.png', bbox_inches='tight', dpi=200)
    plt.close()


if __name__ == '__main__':

    bench_home = '/home/tcolman/Dropbox/SPACE/benchmarks/marenostrum/'
    test = 'sedov'
    benchmark_dir_list = [bench_home+'benchmark_performance_tests_24fe23ee_2025-02-17/'+test,
                          bench_home+'benchmark_performance_tests_b5104a59_2025-02-17/'+test]
    reso_strong = 1024
    nodes_strong = [1,2,4,8,16,32,64]
    plot_execution_time(benchmark_dir_list, reso_strong, nodes_strong)