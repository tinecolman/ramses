# Discoverer

The Discoverer cluster is hosted in Bulgaria at Sofia Tech park.

Docs: https://docs.discoverer.bg/index.html

Support email: helpdesk@discoverer.bg

## Gaining access

Allocations can be awarded through the EuroHPC JU.
Once awarded with an allocation, you can follow the procedure below to setup your access to the cluster.

### Activate account

Generate an ssh key using the recommanded type listed here: 
https://docs.discoverer.bg/ssh_key_generation.html
Then send the public part of the key in reply to the welcome email from support, together with your name and institutional email address.

Update your SSH config:
```
Host discoverer
        User myusername
        Hostname login.discoverer.bg
        IdentityFile .ssh/id_ecdsa_discoverer
```

### Install VPN client

You need to connect to the local network via VPN before you can access the machine, as outlined here:
https://docs.discoverer.bg/vpn_linux_command_line.html

Follow the instructions to install openconnect.
If you are on a new ubuntu OS, you can run into the problem that some of the required out-dated packages are missing. 
This issue is decribed here:
https://github.com/yuezk/GlobalProtect-openconnect/issues/351
You may need to install the missing packages manually before installing GlobalProtect-openconnect:
```
wget http://launchpadlibrarian.net/704701349/libwebkit2gtk-4.0-37_2.43.3-1_amd64.deb
wget http://launchpadlibrarian.net/704701345/libjavascriptcoregtk-4.0-18_2.43.3-1_amd64.deb
sudo dpkg --install libwebkit2gtk-4.0-37_2.43.3-1_amd64.deb
sudo dpkg --install libjavascriptcoregtk-4.0-18_2.43.3-1_amd64.deb
```

Once the client installed, you run it as root:
```
sudo openconnect --protocol=gp --interface=discoverer0 --user=myusername start.discoverer.bg
```
Where myusername should be replaced by the username provided by support. 
Remark that the first password asked is your sudo password of your PC, and the second is that for the VPN that was provided by support.
To check the VPN is working, ping the login node:
```
ping login.discoverer.bg
```

### Login to cluster

Launch the VPN client as decribed above.
Add the ssh key you generated previously to your ssh agent, and connect to the cluster
```
ssh-add .ssh/id_ecdsa_discoverer
ssh myusername@login.discoverer.bg
```
If you updated your ssh config there is no need to load the key in advance. You can simply do
```
ssh discoverer
```

### Checking allocation details

TODO

## Running ramses

### Getting and compiling the code
You can get the code by simply using git clone:
```
git clone https://github.com/ramses-organisation/ramses.git
```

To compile, there are several option available. However, do not use intel compilers on discoverer, as they do not work properly with MPI.
For MPI, you can choose either openmpi or mpich. However, mpich does not work for 35 or more nodes due to a bug in mpi_alltoall:
https://github.com/pmodels/mpich/issues/6708
This means, you'll typically use GCC and OpenMPI. The most recent tested module combination can be found in the file `benchmarks/HPCclusters/discoverer/compilation_modules.sh`

For more information on compiler on discoverer, see
https://docs.discoverer.bg/compilers.html


### Submitting a job

Specifications of how to write a valid job script can be found here:
https://docs.discoverer.bg/writing_slurm_batch.html

Example:
```
#!/bin/bash
#SBATCH --job-name=test01_sedov
#SBATCH --account=ehpc-dev-2024d06-046
#SBATCH --qos=ehpc-dev-2024d06-046
#SBATCH --partition=cn
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --ntasks-per-core=1
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive
#SBATCH --mem 251G
#SBATCH --time=00:10:00
#SBATCH --output=slurm_%j.out
#SBATCH --error=slurm_%j.err

module load gcc/latest
module load openmpi/5/gcc/latest

export DATE=`date +%F_%Hh%M`

mpirun ./ramses3d sedov3d_512.nml > run_${DATE}.log
```

Instead of choosing the general partition cn, you can also directly choose the rack or nodes. See:
https://docs.discoverer.bg/resource_overview.html
Note that when choosing 24 nodes or less, the schedular seems to automatically put the job on nodes in the same IB group, if available. 

Be careful: slurmids are recycles quickly.

## Hardware

Discoverer has only CPU nodes (though it is scheduled to receive an upgrade to add a GPU partition). Each node has 2 AMD EPYC 7H12 processors, totaling 128 cores per node.
Regular nodes have 256 GB RAM, while fat nodes have 1 TB.

A more detailed overview can be found here:
https://docs.discoverer.bg/resource_overview.html
