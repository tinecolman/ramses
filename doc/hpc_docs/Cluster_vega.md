# Vega

The Vega cluster is hosted in Slovenia at IZUM, Maribor

Docs: https://doc.vega.izum.si/

Support email: support@sling.si

## Gaining access

Allocations can be awarded through the EuroHPC JU.
Once awarded with an allocation, you can follow the procedure below to setup your access to the cluster.

### Account creation

To obtain an account, you need to send an email to support with attached the filled and signed PDA form and a public ssh key.

The form can be found here:
https://doc.vega.izum.si/dpa/
Fill in your contact details and your HPC project.
In the case of ramses simulations, the user data will usually consist of the ramses source code, which does not contain personal data.

Instruction for the ssh key can be found here:
https://en-vegadocs.vega.izum.si/ssh/

Generate the key:
```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_vega
```
Show the the public part to add to your email:
```
cat .ssh/id_ed25519_vega.pub
```
To add your key to the ssh agent:
```
ssh-add .ssh/id_ed25519_vega
```
Update your ssh config:
```
# Vega at IZUM, Slovenia
Host vega
        User <username>
        Hostname login.vega.izum.si            
```

### Setup two-factor authentication

Follow the instructions in the email send by support.
Install the authenticator app mentioned in the email on your phone (or use one you already have installed).
To get the QR code that is needes as input, on your computer, ssh to 
```
ssh <username>@otp.vega.izum.si
```
Scan the QR code in the authenticator app on your phone. Confirm the link by inputting the code now displayed on your phone. 
Write down the secret key outputted in the OTP ssh terminal. You can use the key later to configure the OTP generator on other devices.

### Login to cluster

You can now connect
```
ssh vega
```
If needed, unlock your ssh key with your passphrase. Then, it will ask for the 6 digit code displayed on the authenticator app on your phone.


## Running RAMSES

### Getting and compiling the code

You can get the code by simply using git clone:
```
git clone https://github.com/ramses-organisation/ramses.git
```

There are several compilers and mpi versions available as loadable modules, see:
- https://doc.vega.izum.si/compilers/
- https://doc.vega.izum.si/mpi/

Since the machine is made up of AMD processors, you'll typically use GCC and OpenMPI. The most recent tested module combination can be found in the file `benchmarks/HPCclusters/vega/compilation_modules.sh`

### Submitting a job

Use `sbatch`. Example job script:
```
#!/bin/bash
#SBATCH --job-name=sedov16
#SBATCH --partition=cpu
#SBATCH --nodes=16
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=slurm_%j.out
#SBATCH --error=slurm_%j.err

module load GCC
module load openmpi/gnu/4.1.2.1

export DATE=`date +%F_%Hh%M`

srun ./ramses3d sedov3d_2048.nml > run_${DATE}_${SLURM_JOBID}.log
```

## Hardware

### Processor

Vega's CPU nodes have 2 AMD EPYC 7H12 processors, totaling 128 cores per node.
Regular nodes have 256 GB RAM, while high memory nodes have 1 TB. There are 768 standard nodes (8 racks) and 192 high memory nodes (2 racks), totalling 960 cpu nodes.
