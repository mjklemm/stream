# STREAM_ARRAY_SIZE=2500000000
STREAM_ARRAY_SIZE=250000000
NTIMES=10

all: stream.clang-nts stream.clang

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c
	$(FF) $(FFLAGS) -c stream.f
	$(FF) $(FFLAGS) stream.o mysecond.o -o stream_f.exe

stream_c.exe: stream.c
	$(CC) $(CFLAGS) stream.c -o stream_c.exe


stream.icc-nts: Makefile stream.c
	icc -Ofast -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -mcmodel=large -shared-intel -fopenmp -ffreestanding -qopt-streaming-stores always -o stream.icc-nts stream.c

stream.icc: Makefile stream.c
	icc -Ofast -DSTATIC -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -mcmodel=large -shared-intel -fopenmp -ffreestanding -o stream.icc stream.c

stream.clang-nts: Makefile stream.c
	clang -O3 -mavx2 -mcmodel=medium -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -ffp-contract=fast -march=znver2 -fno-unroll-loops -fopenmp -fnt-store -o stream.clang-nts stream.c

stream.clang: Makefile stream.c
	clang -O3 -mavx2 -mcmodel=medium -DSTREAM_TYPE=double -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE) -DNTIMES=$(NTIMES) -ffp-contract=fast -march=znver2 -fno-unroll-loops -fopenmp -o stream.clang stream.c

clean:
	rm -f *.o
	rm -f stream.clang-nts stream.clang
	rm -f stream.icc-nts stream.icc

realclean: clean
	rm -f *.bak *~

.PHONY: all clean realclean
