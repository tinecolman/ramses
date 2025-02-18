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

The raw data is stored in text files, which are uploaded to the git.
The name of the file is: timings_<system>_<testname>.txt
The file contains a table with several columns:
   benchmark date, short commit hash, resolution, number of nodes, list of total execution times
'''

import subprocess
import numpy as np
from matplotlib import pyplot as plt
import matplotlib.colors as colorsx
import matplotlib.cm as cmx

#######################################################################
# I/O
#######################################################################

''' Use grep to get the times from all logfiles in a directory '''
def get_timings_from_log(run_dir):
    subprocess.call("grep --no-filename 'Total elapsed time' {}/*.log".format(run_dir) +" | awk '{print $4}' > total_time.txt", shell=True)
    total_time=np.loadtxt('total_time.txt', unpack=True)
    total_time=np.array([total_time]).flatten()
    return total_time

''' load previous data from file into dicts format '''
def load_data(benchmark_file):
    data = {}

    try: 
        with open(benchmark_file, 'r') as f:
            for line in f:
                currentline = line.strip().split(',')

                # create benchmark entry if not already in dict
                entry_name = currentline[1]+'\n'+currentline[0] #commit name + date
                if entry_name not in data:
                    data[entry_name] = {}

                # cast times to float
                if (currentline[4]=='[]'):
                    timing = np.nan
                else:
                    items = [float(i) for i in (currentline[4][1:-2]).strip().split()]

                # add data to entry
                subentry_name = currentline[2]+' '+currentline[3] #reso nodes
                data[entry_name][subentry_name] = items
    except:
        print("No data to load.")

    return data

''' write the data from dicts format into file '''
def write_data(benchmark_file, data):

    with open(benchmark_file, 'w') as f:
        for entry in data:
            date = entry[-10:]
            commit = entry[:8]
            for subentry in data[entry]:
                [reso, nodes] = subentry.split()
                f.write(f"{date},{commit},{reso},{nodes},{data[entry][subentry]}\n")

    print("Updated", benchmark_file)


''' add data to the dict '''
def add_data(data, benchmark_info, configs):
    # directory where to search log files
    benchmark_dir = f"benchmark_{benchmark_info['branch']}_{benchmark_info['commit']}_{benchmark_info['date']}"
    benchmark_dir = f"{benchmark_info['scratch']}/{benchmark_dir}/{benchmark_info['test']}"

    # check if entry exists
    entry_name = benchmark_info['commit'] + '\n' + benchmark_info['date']
    if entry_name not in data:
        data[entry_name] = {}

    # load and store timings for all configurations
    for (nnodes, reso) in configs:
        # get times from log
        subdir_name = 'nodes'+str(nnodes)+'_reso'+str(reso)
        total_times = get_timings_from_log(benchmark_dir+'/'+subdir_name)
        # add to dict, overwrite if already exist
        subentry_name = str(reso)+' '+str(nnodes) #reso nodes
        data[entry_name][subentry_name] = total_times

    print('Loaded data for benchmark', benchmark_info['commit'], benchmark_info['date'])
    return data


#######################################################################
# Analysis and plotting
#######################################################################

''' Get average time and error bars from the gathered total times printed in the log files '''
def process_times(total_time):
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


'''  '''
def plot_strong_scaling(benchmark_dir, reso_strong, nodes_strong):

    # gather data from log files
    times, errors_min, errors_max = [], [], []
    for nnodes in nodes_strong:
        subdir_name = 'nodes'+str(nnodes)+'_reso'+str(reso_strong)
        time, error_min, error_max, Nav = get_timings_total(benchmark_dir+'/'+subdir_name)
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
#TODO update for refactoring data dict
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

    test = 'sedov'
    bench_home = '/home/tcolman/Dropbox/SPACE/benchmarks/marenostrum/'
    branch = 'performance_tests'

    '''
    import argparse
    parser = argparse.ArgumentParser(description="Analyse benchmark data.")
    parser.add_argument('-s', '--scratch', help="scratch directory")
    parser.add_argument('-b', '--branch', help="Name of the benchmarked branch")
    parser.add_argument('-t', '--test', help="Name of the test case")
    args = parser.parse_args()

    bench_home = args.scratch
    branch = args.branch
    test = args.test
    '''


    #benchmark_dir_list = [bench_home+'benchmark_'+branch+'_24fe23ee_2025-02-17/'+test,
    #                      bench_home+'benchmark_'+branch+'_b5104a59_2025-02-17/'+test]
    reso_strong = 1024
    nodes_strong = [1,2,4,8,16,32,64]
    configs = []
    for n in nodes_strong:
        configs.append((n, reso_strong))
    #plot_execution_time(benchmark_dir_list, reso_strong, nodes_strong)

    benchmark_info = {'system': 'marenostrum',
                      'test': test,
                      'branch': branch,
                      'scratch': bench_home,
                      'commit': '24fe23ee',
                      'date': '2025-02-17'}

    benchmark_file = 'timings_'+benchmark_info['system']+'_'+benchmark_info['test']+'.txt'

    data = load_data(benchmark_file)
    data = add_data(data, benchmark_info, configs)

    benchmark_info = {'system': 'marenostrum',
                      'test': test,
                      'branch': branch,
                      'scratch': bench_home,
                      'commit': 'b5104a59',
                      'date': '2025-02-17'}

    data = add_data(data, benchmark_info, configs)
    write_data(benchmark_file,data)

    # make figures
