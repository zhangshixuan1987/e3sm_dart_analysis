#!/bin/csh
#SBATCH  --job-name=obs-diag
#SBATCH -n 10
#SBATCH -t 02:00:00
#SBATCH -A ESMD
#SBATCH -p short
#SBATCH -e err_dera5.%J
#SBATCH -o out_dera5.%J

module load ncl

set workdir =  /compyfs/zhan391/e3sm_dart/ncl_plot_dart/obs_rmsd_anl

cd $workdir

set j = 1
foreach file (plot_acc_profil*)

 srun -n$j --exclusive ncl $file &

 @ j++
end

wait

