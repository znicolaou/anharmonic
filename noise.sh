#!/bin/bash
#SBATCH -n 16
#SBATCH -a [0-10]
#SBATCH --mem=16gb
#SBATCH --output=outs/%j.out
#SBATCH -p GTX980

module load python/anaconda3.7
source activate my_env
export OMP_NUM_THREADS=1

jid=$((SLURM_ARRAY_TASK_ID))
ZGN_noise=`bc -l <<< "0.0+(0.04-0.0)/10*$jid"`

#calculate high amplitudes initial states
filebase=data/noise/${jid}_1
./pendula.py --verbose 0 --num 1000 --cycles 10000 --outcycle 5000 --dt 0.5 --amplitude 0.05 --noise $ZGN_noise --filebase $filebase &

#increase from 0.04
for tid in `seq 0 50`; do
ZGN_amplitude=`bc -l <<< "0.04+0.01/50*$tid"`
filebase=data/noise/${jid}_${tid}_0
echo $jid $tid $filebase
./pendula.py --verbose 0 --num 1000 --initcycle 2000 --cycles 5000 --outcycle 2500 --dt 0.05 --initamplitude 0.04 --amplitude $ZGN_amplitude --noise $ZGN_noise --filebase $filebase &
js=`jobs | wc -l`
while [ $js -ge 16 ]; do
sleep 1
js=`jobs | wc -l`;
done
done
wait

#decrease from 0.05
for tid in `seq 0 50`; do
ZGN_amplitude=`bc -l <<< "0.04+0.01/50*$tid"`
filebase=data/noise/${jid}_${tid}_1
cp data/noise/${jid}_1fs.npy data/noise/${jid}_${tid}_1ic.npy
echo $jid $tid $filebase
./pendula.py --verbose 0 --num 1000 --initcycle 2000 --cycles 5000 --outcycle 2500 --dt 0.05 --initamplitude 0.05 --amplitude $ZGN_amplitude --noise $ZGN_noise --filebase $filebase &
js=`jobs | wc -l`
while [ $js -ge 16 ]; do
sleep 1
js=`jobs | wc -l`;
done
done
wait
