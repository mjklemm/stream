#!/bin/bash

set +e
set +x

make clean
make stream_c stream_f
OMP_PROC_BIND=true OMP_PLACES=threads ./stream_c
OMP_PROC_BIND=true OMP_PLACES=threads ./stream_f

# KMP_AFFINITY=verbose OMP_NUM_THREADS=32 OMP_PROC_BIND=spread OMP_PLACES='{0},{4},{8},{12},{16},{20},{24},{28},{32},{36},{40},{44},{48},{52},{56},{60},{64},{68},{72},{76},{80},{84},{88},{92},{96},{100},{104},{108},{112},{116},{120},{124}' srun likwid-perfctr -V 3 -o likwid.txt -f -c 0,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120,124 -g MEM ./stream.clang-nts
