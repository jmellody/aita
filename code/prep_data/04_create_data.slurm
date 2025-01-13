#!/bin/bash
#SBATCH --job-name=create_data         # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=1        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=25G         # memory per cpu-core (4G per cpu-core is default)
#SBATCH --time=00:30:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=YOUR EMAIL HERE

module purge
module load stata/18.0
stata -b create_data.do