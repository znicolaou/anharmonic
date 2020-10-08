#!/usr/bin/env python
from __future__ import print_function
import time
import argparse
import sys
import numpy as np
import progressbar
import timeit
from scipy.integrate import ode
from scipy.signal import argrelmax

#Command line arguments
parser = argparse.ArgumentParser(description='Noisy pendula.')
parser.add_argument("--filebase", type=str, required=True, dest='filebase', help='Base string for file output')
parser.add_argument("--num", type=int, default=32, dest='num', help='Number of pendula')
parser.add_argument("--frequency", type=float, default=3.4, dest='freq', help='Driving frequency')
parser.add_argument("--amplitude", type=float, default=0.05, dest='amp', help='Driving amplitude')
parser.add_argument("--delta", type=float, default=0.5, dest='delta', help='Alternating pendulum length scale')
parser.add_argument("--noise", type=float, default=0.0, dest='sigma', help='Noise intensity')
parser.add_argument("--disorder", type=float, default=0.0, dest='epsilon', help='Pendulum length disorder scale')
parser.add_argument("--cycles", type=float, default=1000, dest='cycles', help='Simulation time in driving cycles')
parser.add_argument("--outcycle", type=float, default=1000, dest='outcycle', help='Cycle to start outputting')
parser.add_argument("--average", nargs=2, type=int, default=[50, 100], metavar=('START', 'END'), dest='avg', help='Driving cycles over which to calculate growth rate')
parser.add_argument("--dt", type=float, default=0.05, dest='dt', help='Time between outputs in driving cycles')
parser.add_argument("--noisestep", type=int, default=1, dest='step', help='Noise steps per output timestep')
parser.add_argument("--seed", type=int, default=1, dest='seed', help='Seed for random initial conditions')
parser.add_argument("--damp", type=float, default=0.1, dest='damp', help='Damping coefficient')
parser.add_argument("--spring", type=float, default=1.0, dest='spring', help='Spring coefficient')
parser.add_argument("--init", type=float, default=0.01, dest='init', help='Initial random scale')
parser.add_argument("--rtol", type=float, default=1e-2, dest='rtol', help='Relative error tolerance')
parser.add_argument("--verbose", type=int, default=1, dest='verbose', help='Verbose output')
args = parser.parse_args()

def func(t, y):
		q=y[:N]
		p=y[N:]

		return np.concatenate( [p/lengths, (-args.damp*args.freq*p - (1+args.amp*(args.freq)**2*np.cos(t))*np.sin(q) +args.spring*np.roll(lengths,1)*np.sin(np.roll(q,1)-q)+args.spring*np.roll(lengths,-1)*np.sin(np.roll(q,-1)-q)+args.spring*(np.roll(lengths,1)+np.roll(lengths,-1)-2*lengths)*np.sin(q)+noises)/args.freq**2] )

start = timeit.default_timer()

N=args.num
np.random.seed(args.seed)

ys=np.zeros((int((args.cycles-args.outcycle)/args.dt),2*N))
y=np.zeros(2*N)
y[N:] = args.init*(np.random.random(N)-0.5)
lengths=np.array([1+args.delta*(-1)**i for i in range(N)])+args.epsilon*(np.random.random(N)-0.5)
noises=np.random.normal(0,args.sigma/np.sqrt(args.dt/args.step))
rode=ode(func).set_integrator('vode', rtol=args.rtol, max_step=2*np.pi*args.dt/args.step)
rode.set_initial_value( y, 0 )

if args.verbose==1:
	pbar=progressbar.ProgressBar(widgets=['Integration: ', progressbar.Percentage(), progressbar.Bar(), ' ', progressbar.ETA()], maxval=2*np.pi*args.cycles)
	pbar.start()

for n in range(int(args.cycles/args.dt)):
	for m in range(args.step):
		t=n*2*np.pi*args.dt+m*2*np.pi*args.dt/args.step
		noises=np.random.normal(0,args.sigma/np.sqrt(args.dt/args.step))
		y=rode.integrate(rode.t + 2*np.pi*args.dt/args.step)
	if args.verbose==1:
		pbar.update(t)
	if n >= int(args.outcycle/args.dt):
		ys[n-int(args.outcycle/args.dt)]=y

np.save(args.filebase+"dat",ys)

stop = timeit.default_timer()
if args.verbose==1:
	print('\n runtime: %f' % (stop - start))
else:
	print('runtime: %f' % (stop - start))

file=open(args.filebase+'out.dat','w')
print(*sys.argv,file=file)
print("%i %f %f %f %f %f %f %f %i %i"%(args.num, args.freq, args.amp, args.dt, args.damp, args.epsilon, args.delta,  args.cycles, args.seed, args.step), file=file)
print(*lengths, file=file)

norms=np.sum(ys[int(args.avg[0]/args.dt):int(args.avg[1]/args.dt),:N]**2,axis=1)
maxes=np.array(argrelmax(norms)[0])
fit=np.polyfit(args.dt*maxes, np.log(norms[maxes]),1)[0]
if args.verbose==1:
	print(1.0/np.average(2*np.diff(maxes)*args.dt), fit)

print('runtime: %f' % (stop - start), file=file)
file.close()
