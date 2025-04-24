COMPILER := amd

# DEBUG=-g

ifeq ($(COMPILER), amd)
	FC=amdflang
	FFLAGS=$(DEBUG) -O3

	CC=amdclang
	CFLAGS=$(DEBUG) -O3
endif

STREAM_TYPE=double
STREAM_ARRAY_SIZE=250000000
TYPES=-DDO_COPY=1 -DDO_ADD=1 -DDO_SCALE=1 -DDO_TRIAD=1
NTIMES=10
PARALLEL_INIT=1
COPY=1
ADD=1
SCALE=1
TRIAD=1

DEFINES=-DSTREAM_TYPE=$(STREAM_TYPE) -DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE)
DEFINES+=-DDO_COPY=$(COPY) -DDO_ADD=$(ADD) -DDO_SCALE=$(SCALE) -DDO_TRIAD=$(TRIAD)
DEFINES+=-DPARALLEL_INIT=$(PARALLEL_INIT)

all:
	@echo Please, pick on the of the available stream targets.

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c

stream_f.o: stream.F
	$(FC) $(FOPENMP) $(FFLAGS) $(DEFINES) -o stream_f.o -c stream.F

stream_f: stream_f.o mysecond.o
	$(FC) $(FOPENMP) $(FFLAGS) stream_f.o mysecond.o -o stream_f

stream_c.o: stream.c
	$(CC) $(FOPENMP) $(CFLAGS) $(DEFINES) -o stream_c.o -c stream.c

stream_c: stream_c.o
	$(CC) $(FOPENMP) $(CFLAGS) -o stream_c stream_c.o

clean:
	rm -f *.o
	rm -f stream_c stream_f

realclean: clean
	rm -f *.bak *~

.PHONY: all clean realclean
