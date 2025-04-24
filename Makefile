COMPILER := amd

# DEBUG=-g

ifeq ($(COMPILER), amd)
	FC=amdflang
	FFLAGS=$(DEBUG)

	CC=amdclang
	CFLAGS=$(DEBUG)
endif

STREAM_TYPE=double
STREAM_ARRAY_SIZE=250000000
TYPES=-DDO_COPY=1 -DDO_ADD=1 -DDO_SCALE=1 -DDO_TRIAD=1
# FOPENMP=-fopenmp
NTIMES=10

DEFINES=$(TYPES) -DSTREAM_TYPE=$(STREAM_TYPE) -DSTREAM_ARRAY_SIZEE=$(STREAM_ARRAY_SIZE)

all: stream_f stream_c

mysecond.o: mysecond.c
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
