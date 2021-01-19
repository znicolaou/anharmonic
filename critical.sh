#!/bin/bash
#SBATCH -n 2
#SBATCH -a [1-60]
#SBATCH --mem=64gb
#SBATCH --output=outs/%j.out
#SBATCH -p GTX980

module load python/anaconda3.7
source activate my_env
export OMP_NUM_THREADS=1

jid=$((SLURM_ARRAY_TASK_ID-1))
ZGN_noise=0
ZGN_delta=0.35
ZGN_num=32
filebase0=data/critical2
mkdir -p $filebase0

#calculate high amplitudes initial states
filebase=${filebase0}/${jid}_1
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle 0 --cycles 50000 --outcycle 40000 --dt 0.5 --initamplitude 0.05 --amplitude 0.05 --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi

#increase from 0.025
ZGN_amplitude=`bc -l <<< "0.025+0.01/50*$jid"`
filebase=${filebase0}/${jid}_0
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle 10000 --cycles 50000 --outcycle 40000 --dt 0.5 --initamplitude 0.04 --amplitude $ZGN_amplitude --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi

wait


#decrease from 0.05
ZGN_amplitude=`bc -l <<< "0.025+0.01/50*$jid"`
filebase=${filebase0}/${jid}_1
mv ${filebase0}/${jid}_1fs.npy ${filebase0}/${jid}_1ic.npy
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle 10000 --cycles 50000 --outcycle 40000 --dt 0.5 --initamplitude 0.05 --amplitude $ZGN_amplitude --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi

wait
