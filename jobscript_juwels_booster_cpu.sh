#!/bin/bash -x
#SBATCH --account=cstma
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-core=1
#SBATCH --output=penning_cpu.out
#SBATCH --error=penning_cpu.err
#SBATCH --time=00:15:00
#SBATCH --partition=develbooster
#SBATCH --hint=nomultithread
#SBATCH --gres=gpu:0

export SRUN_CPUS_PER_TASK=48
export OMP_NUM_THREADS=48
export OMP_PROC_BIND=spread
export OMP_PLACES=cores


srun ./PenningTrap 32 32 32 655360 400 FFT 1.0 -b 1.0 --info 5

