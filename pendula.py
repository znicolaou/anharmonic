#!/usr/bin/env python
from __future__ import print_function
import time
import argparse
import sys
import numpy as np
import progressbar
import timeit
from scipy.integrate import ode


#Command line arguments
parser = argparse.ArgumentParser(description='Noisy pendula.')
parser.add_argument("--filebase", type=str, required=True, dest='filebase', help='Base string for file output')
parser.add_argument("--num", type=int, default=32, dest='num', help='Number of pendula')
parser.add_argument("--frequency", type=float, default=3.4, dest='freq', help='Driving frequency in Hertz')
parser.add_argument("--amplitude", type=float, default=0.05, dest='amp', help='Driving amplitude in terms of gravitational acceleration')
parser.add_argument("--delta", type=float, default=0.5, dest='delta', help='Length change')
parser.add_argument("--epsilon", type=float, default=0.0, dest='epsilon', help='Noise intensity')
parser.add_argument("--cycles", type=float, default=1000, dest='cycles', help='Simulation time in driving cycles')
parser.add_argument("--dt", type=float, default=0.05, dest='dt', help='Time between outputs in driving cycles')
parser.add_argument("--noisestep", type=int, default=1, dest='step', help='Noise steps per timestep')
parser.add_argument("--seed", type=int, default=1, dest='seed', help='Seed for random initial conditions')
parser.add_argument("--damp", type=float, default=0.1, dest='damp', help='Damping coefficient')
parser.add_argument("--spring", type=float, default=1.0, dest='spring', help='Spring coefficient')
args = parser.parse_args()


def func(t, y):
		q=y[:N]
		p=y[N:]

		return np.concatenate( [p/lengths, (-args.damp*args.freq*p - (1+args.amp*(args.freq)**2*np.cos(t))*np.sin(q) +args.spring*np.roll(lengths,1)*np.sin(np.roll(q,1)-q)+args.spring*np.roll(lengths,-1)*np.sin(np.roll(q,-1)-q)+args.spring*(np.roll(lengths,1)+np.roll(lengths,-1)-2*lengths)*np.sin(q)+noises)/args.freq**2] )

start = timeit.default_timer()

N=args.num
np.random.seed(args.seed)

ys=np.zeros((int(args.cycles/args.dt),2*N))
y=np.zeros(2*N)
y[:N] = 0.2*(np.random.random(N)-0.5)
lengths=np.array([1+args.delta*(-1)**i for i in range(N)])
noises=2*args.epsilon*(np.random.random(N)-0.5)
rode=ode(func).set_integrator('vode', atol=1e-3, rtol=1e-2, max_step=2*np.pi*args.dt/args.step)
rode.set_initial_value( y, 0 )

pbar=progressbar.ProgressBar(widgets=['Integration: ', progressbar.Percentage(), progressbar.Bar(), ' ', progressbar.ETA()], maxval=2*np.pi*args.cycles)
pbar.start()

for n in range(int(args.cycles/args.dt)):
	for m in range(args.step):
		t=n*2*np.pi*args.dt+m*2*np.pi*args.dt/args.step
		noises=2*args.epsilon*(np.random.random(N)-0.5)
		y=rode.integrate(rode.t + 2*np.pi*args.dt/args.step)
	pbar.update(t)
	ys[n]=y

np.save(args.filebase+"dat",ys)

stop = timeit.default_timer()
print('\n runtime: %f' % (stop - start))

file=open(args.filebase+'out.dat','w')
print(*sys.argv,file=file)
print("%i %f %f %f %f %f %f %f %i %i"%(args.num, args.freq, args.amp, args.dt, args.damp, args.epsilon, args.delta,  args.cycles, args.seed, args.step), file=file)

print('runtime: %f' % (stop - start), file=file)
file.close()
