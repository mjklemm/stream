COMPILER := amd

# Benchmark configuration
STREAM_TYPE_C=double
STREAM_TYPE_F=real(kind=8)
STREAM_ARRAY_SIZE=25000000
TYPES=-DDO_COPY=1 -DDO_ADD=1 -DDO_SCALE=1 -DDO_TRIAD=1
NTIMES=10
OPENMP=1
PARALLEL_INIT=1
COPY=1
ADD=1
SCALE=1
TRIAD=1

ifeq ($(COMPILER), amd)
	FC=amdflang
	FFLAGS=-O3
	FLDFLAGS=

	CC=amdclang
	CFLAGS=-O3 -mavx2 -fnt-store=aggressive
	CLDFLAGS=

	ifeq ($(OPENPMP), 1)
		FOPENMP=-fopenmp
	endif
endif

ifeq ($(COMPILER), intel)
	FC=ifx
	FFLAGS=-O3 -mavx2 -qopt-streaming-stores=always
	FLDFLAGS=

	CC=icx
	CFLAGS=-O3 -mavx2 -qopt-streaming-stores=always
	CLDFLAGS=

	ifeq ($(OPENPMP), 1)
		FOPENMP=-fiopenmp
	endif
endif

CDEFINES=-DSTREAM_TYPE=$(STREAM_TYPE_C)
FDEFINES='-DSTREAM_TYPE=$(STREAM_TYPE_F)'

DEFINES=-DSTREAM_ARRAY_SIZE=$(STREAM_ARRAY_SIZE)
DEFINES+=-DDO_COPY=$(COPY) -DDO_ADD=$(ADD) -DDO_SCALE=$(SCALE) -DDO_TRIAD=$(TRIAD)
DEFINES+=-DPARALLEL_INIT=$(PARALLEL_INIT)

dummy:
	@echo "Please, pick one the of the available stream targets:"
	@echo "all, stream_c, stream_f"

all: stream_f stream_c

stream_f.o: stream.F
	$(FC) $(FOPENMP) $(FFLAGS) $(FDEFINES) $(DEFINES) -o stream_f.o -c stream.F

stream_f: stream_f.o mysecond.o
	$(FC) $(FOPENMP) $(FLDFLAGS) stream_f.o mysecond.o -o stream_f

stream_c.o: stream.c
	$(CC) $(FOPENMP) $(CFLAGS) $(CDEFINES) $(DEFINES) -o stream_c.o -c stream.c

stream_c: stream_c.o
	$(CC) $(FOPENMP) $(CLDFLAGS) -o stream_c stream_c.o

clean:
	rm -f *.o
	rm -f stream_c stream_f

realclean: clean
	rm -f *.bak *~

.PHONY: all clean realclean
