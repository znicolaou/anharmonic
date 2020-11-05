#!/bin/bash
#SBATCH -n 8
#SBATCH -a [1-30]
#SBATCH --mem=64gb
#SBATCH --output=outs/%j.out
#SBATCH -p GTX980

module load python/anaconda3.7
source activate my_env
export OMP_NUM_THREADS=1

jid=$((SLURM_ARRAY_TASK_ID-1))
ZGN_filebase0=data/critical
mkdir -p $ZGN_filebase0
ZGN_freq0=2.0
ZGN_freq1=3.75
ZGN_amp0=0.03
ZGN_amp1=0.05
ZGN_num=50
ZGN_freq=`bc -l <<< "${ZGN_freq0}+(${ZGN_freq1}-${ZGN_freq0})/29*$jid"`
ZGN_noise=0
ZGN_cycle0=5000
ZGN_cycles=10000
ZGN_cycle1=6000

#calculate ZGN_amp1 initial states
filebase=${ZGN_filebase0}/${jid}_ic
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --num 100 --initcycle 0 --cycles $ZGN_cycles --outcycle $ZGN_cycle1 --dt 0.5 --initamplitude $ZGN_amp1 --amplitude $ZGN_amp1 --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi

#increase from ZGN_amp0
for tid in `seq 0 $ZGN_num`; do
ZGN_amplitude=`bc -l <<< "${ZGN_amp0}+(${ZGN_amp1}-${ZGN_amp0})/${ZGN_num}*$tid"`
filebase=${ZGN_filebase0}/${jid}_${tid}_0
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --num 100 --initcycle $ZGN_cycle0 --cycles $ZGN_cycles --outcycle $ZGN_cycle1 --dt 0.5 --initamplitude $ZGN_amp0 --amplitude $ZGN_amplitude --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
else
echo "previously completed"
fi
js=`jobs | wc -l`
while [ $js -ge 8 ]; do
sleep 1
js=`jobs | wc -l`;
done
done

#decrease from ZGN_amp1
for tid in `seq 0 $ZGN_num`; do
ZGN_amplitude=`bc -l <<< "${ZGN_amp0}+(${ZGN_amp1}-${ZGN_amp0})/${ZGN_num}*$tid"`
filebase=${ZGN_filebase0}/${jid}_${tid}_1
cp ${ZGN_filebase0}/${jid}_icfs.npy ${ZGN_filebase0}/${jid}_${tid}_1ic.npy
echo $jid $tid $filebase
if [ ! -f ${filebase}fs.npy ]; then
./pendula.py --verbose 0 --num 100 --initcycle $ZGN_cycle0 --cycles $ZGN_cycles --outcycle $ZGN_cycle1 --dt 0.5 --initamplitude $ZGN_amp1 --amplitude $ZGN_amplitude --frequency $ZGN_freq --noise $ZGN_noise --noisestep 10 --filebase $filebase &
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
rm ${ZGN_filebase0}/${jid}_*.npy
