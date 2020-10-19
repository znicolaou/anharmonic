#!/bin/bash
#SBATCH -n 8
#SBATCH -a [1-50]
#SBATCH --mem=16gb
#SBATCH --output=outs/%j.out
#SBATCH -p GTX980

module load python/anaconda3.7
source activate my_env
export OMP_NUM_THREADS=1

jid=$((SLURM_ARRAY_TASK_ID))
ZGN_noise=`bc -l <<< "0.02+(0.06-0.02)/50*$jid"`

#calculate high and low amplitudes initial states
filebase=data/noise/${jid}_0
./pendula.py --verbose 0 --num 1000 --cycles 10000 --outcycle 5000 --dt 0.5 --amplitude 0.04 --noise $ZGN_noise --filebase $filebase &
filebase=data/noise/${jid}_1
./pendula.py --verbose 0 --num 1000 --cycles 10000 --outcycle 5000 --dt 0.5 --amplitude 0.05 --noise $ZGN_noise --filebase $filebase &
wait

#increase from 0.04
for tid in `seq 1 10`; do
ZGN_amplitude=`bc -l <<< "0.04+0.01/10*$tid"`
filebase=data/noise/${jid}_${tid}_0
cp data/noise/${jid}_0fs.npy data/noise/${jid}_${tid}_0ic.npy
echo $jid $tid $filebase
./pendula.py --verbose 0 --num 1000 --initcycle 500 --cycles 1000 --outcycle 0 --dt 0.05 --initamplitude 0.04 $ZGN_amplitude --noise $ZGN_noise --filebase $filebase &
js=`jobs | wc -l`
while [ $js -ge 8 ]; do
sleep 1
js=`jobs | wc -l`;
done
done
wait

#decrease from 0.05
for tid in `seq 1 10`; do
ZGN_amplitude=`bc -l <<< "0.04+0.01/10*$tid"`
filebase=data/noise/${jid}_${tid}_1
cp data/noise/${jid}_1fs.npy data/noise/${jid}_${tid}_1ic.npy
echo $jid $tid $filebase
./pendula.py --verbose 0 --num 1000 --initcycle 500 --cycles 1000 --outcycle 0 --dt 0.05 --initamplitude 0.05 $ZGN_amplitude --noise $ZGN_noise --filebase $filebase &
js=`jobs | wc -l`
while [ $js -ge 8 ]; do
sleep 1
js=`jobs | wc -l`;
done
done
wait
