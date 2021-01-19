#!/bin/bash
#SBATCH -n 16
#SBATCH -a [1-64]
#SBATCH --mem=64gb
#SBATCH --output=outs/%j.out
#SBATCH -p GTX980

module load python/anaconda3.7
source activate my_env
export OMP_NUM_THREADS=1

jid=$((SLURM_ARRAY_TASK_ID-1))
ZGN_noise=0
ZGN_delta=0.0
ZGN_num=32
ZGN_freq0=3.3
ZGN_freq1=3.7
ZGN_amp0=0.02
ZGN_amp1=0.05
ZGN_steps=64
ZGN_cycles=5000
ZGN_outcycle=4000
ZGN_initcycle=1000

filebase0=data/critical2
mkdir -p $filebase0

ZGN_freq=`bc -l <<< "${ZGN_freq0}+(${ZGN_freq1}-${ZGN_freq0})/${ZGN_steps}*$jid"`

#calculate high amplitudes initial states
filebase=${filebase0}/${jid}_1
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle 0 --cycles $ZGN_cycles --outcycle $ZGN_outcycle --dt 0.5 --initamplitude $ZGN_amp1 --amplitude $ZGN_amp1 --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi

#increase from 0.025
for tid in `seq 0 $ZGN_steps`; do
ZGN_amp=`bc -l <<< "${ZGN_amp0}+(${ZGN_amp1}-${ZGN_amp0})/${ZGN_steps}*$jid"`
filebase=${filebase0}/${jid}_${tid}_0
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle $ZGN_initcycle --cycles $ZGN_cycles --outcycle $ZGN_outcycle --dt 0.5 --initamplitude $ZGN_amp0 --amplitude $ZGN_amp --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi
js=`jobs | wc -l`
while [ $js -ge 16 ]; do
sleep 1
js=`jobs | wc -l`;
done
done
wait

#decrease from 0.05
for tid in `seq 0 $ZGN_steps`; do
ZGN_amp=`bc -l <<< "${ZGN_amp0}+(${ZGN_amp1}-${ZGN_amp0})/${ZGN_steps}*$jid"`
filebase=${filebase0}/${jid}_${tid}_1
mv ${filebase0}/${jid}_1fs.npy ${filebase0}/${jid}_${tid}_1ic.npy
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle $ZGN_initcycle --cycles $ZGN_cycles --outcycle $ZGN_outcycle --dt 0.5 --initamplitude $ZGN_amp1 --amplitude $ZGN_amp --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi
js=`jobs | wc -l`
while [ $js -ge 16 ]; do
sleep 1
js=`jobs | wc -l`;
done
done

wait
rm ${filebase0}/*.npy
