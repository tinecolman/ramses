# Karolina

The Karolina cluster is one of the clusters hosted by IT4Innovations in Czech Republic.

Docs: https://docs.it4i.cz/

Support email: support@it4i.cz

IT4I profile settings: https://docs.it4i.cz/general/management/it4i-profile/


## Gaining access

Allocations can be awarded through the EuroHPC JU.
Once awarded with an allocation, you can follow the procedure below to setup your access to the cluster.

### Generate an SSH key

If not already done so, generate an ssh key.
More information on ssh keys can be found on this page TODO.

Update your SSH config:
```
Host karolina
        User myusername
        Hostname karolina.it4i.cz
        IdentityFile .ssh/id_of_the_generated_key
```

### Obtain a certificate to be able to send a digitally signed email

https://docs.it4i.cz/general/obtaining-login-credentials/obtaining-login-credentials/

You will need to request your account by sending a digitally signed email.
There are multiple options to obtain a certificate to be able to send such a signed email.

If you are part of CNRS you can generate a CNRS certificate, as explained here:
https://support.dr7.cnrs.fr/pages/exec.php/object/view/FAQ/25?exec_module=itop-portal-base&exec_page=index.php&portal_id=itop-portal
- Make sure the email you use to login to Janus is your CNRS email. If this is not the case, ask RH to change it.
- Go to https://sesame.cnrs.fr/ -> "Manage my certificates" and select CNRS
- Next, click on "Demander un nouveau certificat personel". Once generated, the certificate will be downloaded.

Alternatively, you can request a free Actalis S/MIME certificate:
https://www.actalis.com/request-s-mime-certificate
In this case, you will need to add a copy of an identification document such as a passport or drivers license to the email.

### Setup certificate into mail client

Once you have obtained the certificate, import it into your mail client (it will not work with webmail).
https://services.renater.fr/tcs/faq/tcs_personnes/utiliser#securiser_les_courriers_electroniques_a_l_aide_d_une_signature_numerique
On Linux, you can use Thunderbird:
- Settings -> Account settings (at the bottom) -> End-to-end encryption
- Scroll to the S/MIME section and click "manage certificates"
- Under "your certificates", press import and select the certificate you obtained in the previous step. Click ok.
- You can now set the certificate for digital signing.
- When writing an email, you will now have a menu S/MIME were you can mark that the email should be digitally signed.

### Request your IT4I account

You will need to request your account by sending a digitally signed email containing the information listed here:
https://docs.it4i.cz/general/obtaining-login-credentials/obtaining-login-credentials/
Once approved, you will receive an email with your username and a password for updating your profile settings.
You can now set your ssh key through the portal, and also change the password of the portal:
https://docs.it4i.cz/general/management/it4i-profile/

You will need to wait for a second email to confirm access to the different clusters, once your participation to the project has been approved by the project PI.


### Login to cluster


Add your ssh key to the key manager
```
$ ssh-add .ssh/id_ed25519_karolina
```
You can now connect to the cluster through ssh:
```
$ ssh myusername@karolina.it4i.cz
```

For convenience, you can add this information to your ssh config file:
```
Host karolina
        User it4i-tcolman
        Hostname karolina.it4i.cz
```
and simply use
```
ssh karolina
```

### Checking allocation details
 
TODO

## Running ramses

### Getting and compiling the code
You can get the code by simply using git clone on the login node:
```
git clone https://github.com/ramses-organisation/ramses.git
```

A list of available compiler and mpi modules can be found here:
- https://docs.it4i.cz/software/compilers/
- https://docs.it4i.cz/software/mpi/mpi/
The most recent tested module combination can be found in the file `benchmarks/HPCclusters/karolina/compilation_modules.sh`

For more information on compiler on discoverer, see
https://docs.discoverer.bg/compilers.html


### Submitting a job

Specifications of how to write a valid job script can be found here:
https://docs.it4i.cz/general/job-submission-and-execution/

Example
```
#!/bin/bash -l
#SBATCH --job-name=test
#SBATCH --account=open-30-28
#SBATCH --partition=qcpu
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --time=00:10:00
#SBATCH --output=slurm_%j.out
#SBATCH --error=slurm_%j.err

module purge
module load GCC/13.2.0
module load OpenMPI/4.1.6-GCC-13.2.0

export DATE=`date +%F_%Hh%M`

srun ./ramses3d sedov3d_2048.nml > run_${DATE}_${SLURM_JOBID}.log
```


## Hardware

Each node has 2 AMD EPYC 7H12 processors, totaling 128 cores per node. The default clock speed is reduced to 2.1 GHz.
Nodes have 256 GB RAM.

A more detailed overview can be found here:
https://docs.it4i.cz/karolina/compute-nodes/
