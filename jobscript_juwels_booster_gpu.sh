#!/bin/bash -x
#SBATCH --account=cstma
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=4
#SBATCH --output=penning_gpu.out
#SBATCH --error=penning_gpu.error
#SBATCH --time=00:15:00
#SBATCH --partition=develbooster
#SBATCH --gres=gpu:4

srun ./PenningTrap 32 32 32 655360 400 FFT 1.0 -b 1.0 --info 5
