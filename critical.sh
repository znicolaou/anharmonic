#!/bin/bash
#SBATCH -n 8
#SBATCH -a [1-65]
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
ZGN_cycles=25000
ZGN_outcycle=20000
ZGN_initcycle=5000

filebase0=data/critical2
mkdir -p $filebase0

ZGN_freq=`bc -l <<< "${ZGN_freq0}+(${ZGN_freq1}-${ZGN_freq0})/${ZGN_steps}*$jid"`

#From random initial conditions
for tid in `seq 0 $ZGN_steps`; do
ZGN_amp=`bc -l <<< "${ZGN_amp0}+(${ZGN_amp1}-${ZGN_amp0})/${ZGN_steps}*$tid"`
filebase=${filebase0}/${jid}_${tid}_0
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle 0 --cycles $ZGN_cycles --outcycle $ZGN_outcycle --dt 0.5 --initamplitude $ZGN_amp --amplitude $ZGN_amp --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi
js=`jobs | wc -l`
while [ $js -ge 8 ]; do
sleep 1
js=`jobs | wc -l`;
done
done
wait

#Find the first non-zero order parameter, and use this as the initial condition/amplitude.
tid=0
ZGN_stop=0
while [ $ZGN_stop -eq 0 ] && [ $tid -le $ZGN_steps ]; do
growth=`tail -n 2  ${ZGN_filebase0}/${jid}_${tid}_0out.dat | head -n 1 | cut -d' ' -f6`
echo $growth
ZGN_stop=`bc -l <<< "$growth > 0.01"`
tid=$((tid+1))
done
echo critical driving at $tid
filebase1=${ZGN_filebase0}/${jid}_${tid}

#decrease from ZGN_amp1
for tid in `seq 0 $ZGN_steps`; do
ZGN_amp=`bc -l <<< "${ZGN_amp0}+(${ZGN_amp1}-${ZGN_amp0})/${ZGN_steps}*$tid"`
filebase=${filebase0}/${jid}_${tid}_1
cp ${filebase1}_0fs.npy ${filebase0}/${jid}_${tid}_1ic.npy
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --delta $ZGN_delta --num $ZGN_num --initcycle $ZGN_initcycle --cycles $ZGN_cycles --outcycle $ZGN_outcycle --dt 0.5 --initamplitude $ZGN_amp1 --amplitude $ZGN_amp --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi
js=`jobs | wc -l`
while [ $js -ge 8 ]; do
sleep 1
js=`jobs | wc -l`;
done
done

wait
rm ${filebase0}/${jid}_*.npy
