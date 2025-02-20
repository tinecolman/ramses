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
'''

import numpy as np
from matplotlib import pyplot as plt
import matplotlib.colors as colorsx
from collections import OrderedDict
from io_timings import update_timings, load_data
from collections import OrderedDict


reso_strong = 1024
nodes_strong = [1,2,4,8,16,32,64]

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

''' Take together timings executed on different day of the same month, for the same commit '''
def merge_data_for_month(data):
    merged_data = OrderedDict()
    print(data)

    for entry in data:
        # remove day from entry date
        new_entry = entry[:-3]
        # add commit-year-month enrty to new dict
        if new_entry not in merged_data:
            merged_data[new_entry] = {}
        for subentry in data[entry]:
            if subentry not in merged_data[new_entry]:
                merged_data[new_entry][subentry] = []
            # join lists
            merged_data[new_entry][subentry] += data[entry][subentry]

    print(merged_data)
    return merged_data

def gather_execution_time_data(data):
    # make an entry for each possible number of nodes
    nodes_strong = range(1,512)
    dates = OrderedDict({n:[] for n in nodes_strong})
    times = OrderedDict({n:[] for n in nodes_strong})
    errors_min = OrderedDict({n:[] for n in nodes_strong})
    errors_max = OrderedDict({n:[] for n in nodes_strong})

    # gather available data
    for entry in data:
        for n in nodes_strong:
            subentry = str(reso_strong)+' '+str(n)
            if subentry in data[entry]:
                time, error_min, error_max = process_times(data[entry][subentry])
                dates[n].append(entry)
                times[n].append(time)
                errors_min[n].append(error_min)
                errors_max[n].append(error_max)

    # remove unused entries
    for n in nodes_strong:
        if dates[n]==[]:
            del dates[n]
            del times[n]
            del errors_min[n]
            del errors_max[n]

    return dates, times, errors_min, errors_max

def gather_strong_scaling_data(data, reso_strong):
    # make an entry for each possible number of nodes
    nodes_strong = range(1,512)
    dates = OrderedDict({n:[] for n in nodes_strong})
    times = OrderedDict({n:[] for n in nodes_strong})
    errors_min = OrderedDict({n:[] for n in nodes_strong})
    errors_max = OrderedDict({n:[] for n in nodes_strong})

    # gather available data
    strong_scaling = OrderedDict()
    for entry in data:
        strong_scaling[entry] = ([],[])
        for n in nodes_strong:
            subentry = str(reso_strong)+' '+str(n)
            if subentry in data[entry]:
                time, error_min, error_max = process_times(data[entry][subentry])
                strong_scaling[entry][0].append(n)
                strong_scaling[entry][1].append(time)

    return strong_scaling


def plot_strong_scaling(data, reso_strong, axes=None):

    #gather data for plotting
    strong_scaling = gather_strong_scaling_data(data, reso_strong)

    # create colors
    cmap = plt.get_cmap('gray_r')
    cNorm  = colorsx.Normalize(vmin=-1, vmax=len(strong_scaling)-1)
    colorVals =  []
    for val in range(len(strong_scaling)):
        colorVals.append(cmap(cNorm(val)))

    # create figure if none is given
    save_plot=False
    if axes==None:
        fig, axes = plt.subplots(nrows=1, ncols=1, figsize=(5,4))
        save_plot=True

    # plot all entries as lines
    max_nodes = 1
    for entry, c in zip(strong_scaling,colorVals):
        print(strong_scaling[entry])
        nodes = strong_scaling[entry][0]
        max_nodes = max(max_nodes, max(nodes))
        times = strong_scaling[entry][1]
        speedups = times[0]*nodes[0]/times
        axes.plot(nodes, speedups, color=c, label=entry)

    # plot last entry also as circles
    if strong_scaling: #if dict is not empty
        axes.scatter(nodes, speedups, color=c)
    
    # add ideal scaling line
    axes.plot([1,max_nodes],[1,max_nodes], c=(0.25,0.85,0.25),ls=':', lw=2)

    axes.set_xlabel('number of nodes')
    axes.set_ylabel('speedup')
    axes.set_xscale('log')
    axes.set_yscale('log')
    axes.legend()
    if save_plot:
        plt.savefig('strong_scaling.png', bbox_inches='tight', dpi=200)
        plt.close()


''' Plot of the evolution of execution time for different number of nodes '''
def plot_execution_time(data, axes=None):

    #gather data for plotting
    dates, times, errors_min, errors_max = gather_execution_time_data(data)
    nodes_strong = dates.keys()

    # create colors
    cmap = plt.get_cmap('managua')
    cNorm  = colorsx.Normalize(vmin=0, vmax=len(nodes_strong)-1)
    colorVals =  []
    for val in range(len(nodes_strong)):
        colorVals.append(cmap(cNorm(val)))

    # plot
    save_plot=False
    if axes==None:
        fig, axes = plt.subplots(nrows=1, ncols=1, figsize=(5,4))
        save_plot=True
    for n, c in zip(nodes_strong,colorVals):
        axes.errorbar(dates[n], times[n], yerr=[errors_min[n],errors_max[n]], fmt='o', markersize=5,
                     label=str(n)+' nodes', color=c)
        # plot a line from the last point to make comparison easier
        axes.plot([dates[n][0],dates[n][-1]], [times[n][-1],times[n][-1]], ls=':', lw=1.3, color=c)

    if save_plot:
        axes.set_ylabel('execution time [s]')
        axes.set_yscale('log')
        axes.tick_params(axis='x', labelrotation=90)
        axes.legend()
        plt.savefig('execution_time.png', bbox_inches='tight', dpi=200)
        plt.close()


''' Show evolution of execution time on EuroHPC systems '''
def eurohpc_dashboard(test_name, statistic='time', reso_strong=1024):

    #euroHPC_systems = ['discoverer', 'karolina', 'meluxina', 'vega',
    #                   'deucalion', 'leonardo', 'lumi', 'marenostrum']
    euroHPC_systems = ['meluxina']

    fig, axes = plt.subplots(nrows=2, ncols=2, figsize=(10,8), sharey=True)

    for cluster, ax in zip(euroHPC_systems, axes.flatten()):
        benchmark_file = 'results/timings_'+cluster+'_'+test_name+'.txt'
        data = load_data(benchmark_file)
        data = merge_data_for_month(data)
        if statistic=='time':
            plot_execution_time(data, axes=ax)
        elif statistic=='strong':
            plot_strong_scaling(data, reso_strong, axes=ax)
        ax.set_title(cluster)

    # fanciness
    if statistic=='time':
        axes[0,0].set_ylabel('execution time [s]')
        axes[1,0].set_ylabel('execution time [s]')
        axes[0,0].set_yscale('log')
        for ax in axes.flatten():
            ax.tick_params(axis='x', labelrotation=90)
            ax.legend()

    #fig.subplots_adjust(wspace=0.1)
    fig.tight_layout()
    plt.savefig(f'eurohpc_dashboard_{statistic}_{test_name}.png', bbox_inches='tight', dpi=200)
    plt.close()


''' (for testing purposes) add locally stored benchmark results to file '''
def make_files():

    bench_home = '/home/tcolman/Dropbox/SPACE/benchmarks/'
    test='sedov'

    cluster = 'marenostrum'
    #update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_24fe23ee_2025-02-17/'+test, test)
    #update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_b5104a59_2025-02-17/'+test, test)

    cluster = 'meluxina'
    update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_2025-02-14_c41fffd1/'+test, test)
    update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_2025-02-18_c172e905/'+test, test)
    update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_2025-02-19_c172e905/'+test, test)
    update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_2025-02-19_c3a66c16/'+test, test)
    update_timings(cluster, bench_home+'/'+cluster+'/'+'benchmark_performance_tests_2025-02-19_8543d1bb/'+test, test)


if __name__ == '__main__':

    #make_files()

    eurohpc_dashboard('sedov', statistic='time')
    #eurohpc_dashboard('sedov', statistic='strong', reso_strong=1024)

    # maybe cool to have the combo weak-strong scaling plot