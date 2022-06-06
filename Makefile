# STREAM_ARRAY_SIZE=2500000000
STREAM_ARRAY_SIZE=250000000
# STREAM_ARRAY_SIZE=25000000
# STREAM_ARRAY_SIZE=2500000
# STREAM_ARRAY_SIZE=250000
# STREAM_ARRAY_SIZE=25000

NTIMES=10
PARALLEL_INIT=1
COPY=1
ADD=1
SCALE=1
TRIAD=1

# DEBUG=-g

BNCH_TYPE=-DDO_COPY=$(COPY) -DDO_ADD=$(ADD) -DDO_SCALE=$(SCALE) -DDO_TRIAD=$(TRIAD)
INIT_TYPE=-DPARALLEL_INIT=$(PARALLEL_INIT)

all:
	@echo Please, pick on the of the available stream targets.

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c
	$(FF) $(FFLAGS) -c stream.f
	$(FF) $(FFLAGS) stream.o mysecond.o -o stream_f.exe

stream_c.exe: stream.c
	$(CC) $(CFLAGS) stream.c -o stream_c.exe

stream.icc-nts: Makefile stream.c
	icc $(DEBUG) -fno-alias -Ofast $(BNCH_TYPE) $(INIT_TYPE) -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -shared-intel -fopenmp -ffreestanding -qopt-streaming-stores always -o stream.icc-nts stream.c

stream.icc: Makefile stream.c
	icc $(DEBUG) -fno-alias -Ofast $(BNCH_TYPE) $(INIT_TYPE) -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -shared-intel -fopenmp -ffreestanding -o stream.icc stream.c

stream.clang-nts: Makefile stream.c
	clang $(DEBUG) -O3 -mavx2 -mcmodel=large $(BNCH_TYPE) $(INIT_TYPE) -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -ffp-contract=fast -march=znver2 -fno-unroll-loops -fopenmp -fnt-store -o stream.clang-nts stream.c

stream.clang: Makefile stream.c
	clang $(DEBUG) -O3 -mavx2 -mcmodel=large $(BNCH_TYPE) $(INIT_TYPE) -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -ffp-contract=fast -march=znver2 -fno-unroll-loops -fopenmp -o stream.clang stream.c

stream.gpu-mi50: Makefile stream.c
	clang $(DEBUG) -O3 $(BNCH_TYPE) $(INIT_TYPE) -DGPU_STREAM=1 -DGPU_DATA_ENV=1 -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -fopenmp -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa -march=gfx906 -o stream.gpu-mi50 stream.c

stream.gpu-mi100: Makefile stream.c
	clang $(DEBUG) -O3 $(BNCH_TYPE) $(INIT_TYPE) -DGPU_STREAM=1 -DGPU_DATA_ENV=1 -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -fopenmp -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa -march=gfx908 -o stream.gpu-mi100 stream.c

stream.gpu-mi200: Makefile stream.c
	clang $(DEBUG) -O3 $(BNCH_TYPE) $(INIT_TYPE) -DGPU_STREAM=1 -DGPU_DATA_ENV=1 -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -fopenmp -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa -march=gfx90a -o stream.gpu-mi100 stream.c

stream.gpu-v100: Makefile stream.c
	#clang $(DEBUG) -O3 $(BNCH_TYPE) $(INIT_TYPE) -DGPU_STREAM=1 -DGPU_DATA_ENV=1 -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -fopenmp -fopenmp-targets=nvptx64-nvidia-cuda -Xopenmp-target -march=sm_70 -o stream.gpu-v100 stream.c
	nvc $(DEBUG) -O3 $(BNCH_TYPE) $(INIT_TYPE) -DGPU_STREAM=1 -DGPU_DATA_ENV=1 -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -mp=gpu -gpu=cc70 -o stream.gpu-v100 stream.c

clean:
	rm -f *.o
	rm -f stream.clang-nts stream.clang
	rm -f stream.icc-nts stream.icc
	rm -f stream.gpu-mi50 stream.gpu-mi100 stream.gpu-mi200
	rm -f stream.gpu-v100 stream.gpu-a100

realclean: clean
	rm -f *.bak *~

.PHONY: all clean realclean
