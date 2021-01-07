#!/bin/bash 

KMP_AFFINITY=verbose OMP_NUM_THREADS=32 OMP_PROC_BIND=spread OMP_PLACES='{'0},{4},{8},{12},{16},{20},{24},{28},{32},{36},{40},{44},{48},{52},{56},{60},{64},{68},{72},{76},{80},{84},{88},{92},{96},{100},{104},{108},{112},{116},{120},{124'}' srun likwid-perfctr -c 0-127 -g MEM_DP stream.clang-nts
