'''
Functions to read/write benchmark data to file

The timings are extracted from the logfiles and stored in text files,
ready to be uploaded to the git.
The name of the file is: timings_<system>_<testname>.txt
The file contains a table with several columns:
   benchmark date, short commit hash, resolution, number of nodes, list of total execution times
'''

import os
import subprocess
from collections import OrderedDict

''' dissect name of the benchmark directory '''
def get_info_from_dir_name(benchmark_dir):
    parts = benchmark_dir.split('/')
    date = parts[-2][-19:-9]
    commit = parts[-2][-8:]
    return date, commit

''' get a list of configurations for which the test has been executated '''
def get_configs(benchmark_dir):
    configs = []
    # list subdirectories in benchmark test
    for item in os.listdir(benchmark_dir):
        name = os.path.join(benchmark_dir, item)
        if os.path.isdir(name) and item.startswith('nodes'):
            # get number of nodes and resolution of config
            [nodes, reso] = item.split('_')
            nodes = int(nodes[5:])
            reso = reso[4:]
            configs.append((nodes,reso))
    #sort according to accending resolution and number of nodes
    configs = sorted(configs, key=lambda tup: tup[0])
    configs = sorted(configs, key=lambda tup: tup[1])
    return configs

''' Use grep to get the times from all logfiles in a directory '''
def get_timings_from_log(run_dir):
    subprocess.call("grep --no-filename 'Total elapsed time' {}/*.log".format(run_dir) +" | awk '{print $4}' > total_time.txt", shell=True)
    with open('total_time.txt', 'r') as file:
        total_time = [float(line.strip()) for line in file]
    return total_time

''' load previous data from file into dicts format '''
def load_data(benchmark_file):
    data = OrderedDict()

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
                    items = []
                else:
                    items = [float(i) for i in (currentline[4][1:-2]).strip().split()]

                # add data to entry
                subentry_name = currentline[2]+' '+currentline[3] #reso nodes
                data[entry_name][subentry_name] = items
    except:
        print(benchmark_file,"not found. No data to load.")

    return data

''' write the data from dicts format into file '''
def write_data(benchmark_file, data):

    with open(benchmark_file, 'w') as f:
        for entry in data:
            date = entry[-10:]
            commit = entry[:8]
            for subentry in data[entry]:
                [reso, nodes] = subentry.split()
                timings_string = str(data[entry][subentry]).replace(',','')
                f.write(f"{date},{commit},{reso},{nodes},{timings_string}\n")

    print("Updated", benchmark_file)

''' add data to the dict '''
def add_data(data, benchmark_dir):

    date, commit = get_info_from_dir_name(benchmark_dir)

    # check if entry exists
    entry_name = commit + '\n' + date
    if entry_name not in data:
        data[entry_name] = {}

    # get a list of the num_nodes-resolution configurations used
    configs = get_configs(benchmark_dir)

    # load and store timings for all configurations
    for (nnodes, reso) in configs:
        # get times from log
        subdir_name = 'nodes'+str(nnodes)+'_reso'+str(reso)
        total_times = get_timings_from_log(benchmark_dir+'/'+subdir_name)
        # add to dict, overwrite if already exist
        subentry_name = str(reso)+' '+str(nnodes) #reso nodes
        data[entry_name][subentry_name] = total_times

    #print('Loaded data for benchmark', commit, date)
    return data


''' Update the timings with a new benchmark '''
def update_timings(cluster, benchmark_dir, test_name):
    benchmark_file = 'timings_'+cluster+'_'+test_name+'.txt'
    # load existing data
    data = load_data(benchmark_file)
    # add/update benchmark entry
    data = add_data(data, benchmark_dir)
    # update file
    write_data(benchmark_file, data)


if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description="Extract benchmark timings and save to file.")
    parser.add_argument('cluster', help="HPC system on which the benchmark has been run")
    parser.add_argument('benchmark_dir', help="directory where the benchmarks have been executed")
    parser.add_argument('test', help="name of the test case")
    args = parser.parse_args()

    update_timings(args.cluster, args.benchmark_dir, args.test)
