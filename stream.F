*=======================================================================
* Program: STREAM
* Programmer: John D. McCalpin
* RCS Revision: $Id: stream.f,v 5.6 2005/10/04 00:20:48 mccalpin Exp mccalpin $
*-----------------------------------------------------------------------
* Copyright 1991-2003: John D. McCalpin
*-----------------------------------------------------------------------
* License:
*  1. You are free to use this program and/or to redistribute
*     this program.
*  2. You are free to modify this program for your own use,
*     including commercial use, subject to the publication
*     restrictions in item 3.
*  3. You are free to publish results obtained from running this
*     program, or from works that you derive from this program,
*     with the following limitations:
*     3a. In order to be referred to as "STREAM benchmark results",
*         published results must be in conformance to the STREAM
*         Run Rules, (briefly reviewed below) published at
*         http://www.cs.virginia.edu/stream/ref.html
*         and incorporated herein by reference.
*         As the copyright holder, John McCalpin retains the
*         right to determine conformity with the Run Rules.
*     3b. Results based on modified source code or on runs not in
*         accordance with the STREAM Run Rules must be clearly
*         labelled whenever they are published.  Examples of
*         proper labelling include:
*         "tuned STREAM benchmark results"
*         "based on a variant of the STREAM benchmark code"
*         Other comparable, clear and reasonable labelling is
*         acceptable.
*     3c. Submission of results to the STREAM benchmark web site
*         is encouraged, but not required.
*  4. Use of this program or creation of derived works based on this
*     program constitutes acceptance of these licensing restrictions.
*  5. Absolutely no warranty is expressed or implied.
*-----------------------------------------------------------------------
* This program measures sustained memory transfer rates in MB/s for
* simple computational kernels coded in FORTRAN.
*
* The intent is to demonstrate the extent to which ordinary user
* code can exploit the main memory bandwidth of the system under
* test.
*=======================================================================
* The STREAM web page is at:
*          http://www.streambench.org
*
* Most of the content is currently hosted at:
*          http://www.cs.virginia.edu/stream/
*
* BRIEF INSTRUCTIONS:
*       0) See http://www.cs.virginia.edu/stream/ref.html for details
*       1) STREAM requires a timing function called mysecond().
*          Several examples are provided in this directory.
*          "CPU" timers are only allowed for uniprocessor runs.
*          "Wall-clock" timers are required for all multiprocessor runs.
*       2) The STREAM array sizes must be set to size the test.
*          The value "N" must be chosen so that each of the three
*          arrays is at least 4x larger than the sum of all the last-
*          level caches used in the run, or 1 million elements, which-
*          ever is larger.
*          ------------------------------------------------------------
*          Note that you are free to use any array length and offset
*          that makes each array 4x larger than the last-level cache.
*          The intent is to determine the *best* sustainable bandwidth
*          available with this simple coding.  Of course, lower values
*          are usually fairly easy to obtain on cached machines, but
*          by keeping the test to the *best* results, the answers are
*          easier to interpret.
*          You may put the arrays in common or not, at your discretion.
*          There is a commented-out COMMON statement below.
*          Fortran90 "allocatable" arrays are fine, too.
*          ------------------------------------------------------------
*       3) Compile the code with full optimization.  Many compilers
*          generate unreasonably bad code before the optimizer tightens
*          things up.  If the results are unreasonably good, on the
*          other hand, the optimizer might be too smart for me
*          Please let me know if this happens.
*       4) Mail the results to mccalpin@cs.virginia.edu
*          Be sure to include:
*               a) computer hardware model number and software revision
*               b) the compiler flags
*               c) all of the output from the test case.
*          Please let me know if you do not want your name posted along
*          with the submitted results.
*       5) See the web page for more comments about the run rules and
*          about interpretation of the results.
*
* Thanks,
*   Dr. Bandwidth
*=========================================================================
*

#ifndef STREAM_ARRAY_SIZE
#   define STREAM_ARRAY_SIZE    10000000
#endif

#ifdef NTIMES
#if NTIMES<=1
#   define NTIMES   10
#endif
#endif
#ifndef NTIMES
#   define NTIMES   10
#endif

#ifndef OFFSET
#   define OFFSET   0
#endif

#ifndef STREAM_TYPE
#define STREAM_TYPE double
#endif

      PROGRAM stream
      IMPLICIT NONE
C     .. Parameters ..
      INTEGER(8) n,offset,ndim,ntimes
      PARAMETER (n=STREAM_ARRAY_SIZE,offset=OFFSET)
      PARAMETER (ndim=n+offset,ntimes=NTIMES)
C     ..
C     .. Local Scalars ..
      DOUBLE PRECISION t
      INTEGER(8) j,k,nbpw,quantum
C     ..
C     .. Local Arrays ..
      DOUBLE PRECISION maxtime(4),mintime(4),avgtime(4),
     $                 times(4,ntimes)
      INTEGER(8) bytes(4)
      CHARACTER label(4)*11
      INTEGER(8) enabled(4)
C     ..
C     .. External Functions ..
      DOUBLE PRECISION mysecond
      INTEGER(8) checktick,realsize
      EXTERNAL mysecond,checktick
!$    INTEGER(8) omp_get_num_threads
!$    EXTERNAL omp_get_num_threads
C     ..
C     .. Intrinsic Functions ..
C
      INTRINSIC dble,max,min,nint,sqrt
C     ..
C     .. Arrays in Common ..
      STREAM_TYPE a(ndim),b(ndim),c(ndim)
      STREAM_TYPE scalar
C     ..
C     .. Common blocks ..
*     COMMON a,b,c
C     ..
C     .. Data statements ..
      DATA avgtime/4*0.0D0/,mintime/4*1.0D+36/,maxtime/4*0.0D0/
      DATA label/'Copy:      ','Scale:     ','Add:       ',
     $     'Triad:     '/
      DATA bytes/2,2,3,3/
      DATA enabled/DO_COPY,DO_SCALE,DO_ADD,DO_TRIAD/
C     ..
C     Helper stuff
C     ..
      INTEGER(8), PARAMETER :: gb = 1024 * 1024 * 1024;
      STREAM_TYPE :: dummy
      REAL(KIND=8) :: readset, writeset
*       --- SETUP --- determine precision and check timing ---

      realsize = sizeof(dummy)
      nbpw = realsize

      PRINT *,'----------------------------------------------'
      PRINT *,'STREAM (Fortran) Version $Revision: 5.6 $'
      PRINT *,'----------------------------------------------'
      WRITE (*,FMT=9010) 'Array size = ',n
      WRITE (*,FMT=9010) 'Offset     = ',offset
      WRITE (*,FMT=9020) 'The total memory requirement is ',
     $  3*nbpw*n/ (1024*1024),' MB'
      WRITE (*,FMT=9030) 'You are running each test ',ntimes,' times'
      WRITE (*,FMT=9030) '--'
      WRITE (*,FMT=9030) 'The *best* time for each test is used'
      WRITE (*,FMT=9030) '*EXCLUDING* the first and last iterations'

!$OMP PARALLEL
!$OMP MASKED FILTER(0)
      PRINT *,'----------------------------------------------'
!$    PRINT *,'Number of Threads = ',OMP_GET_NUM_THREADS()
!$OMP END MASKED
!$OMP END PARALLEL

      PRINT *,'----------------------------------------------'
!$OMP PARALLEL
      PRINT *,'Printing one line per active thread....'
!$OMP END PARALLEL

      PRINT *,'----------------------------------------------'
#if PARALLEL_INIT
      PRINT *, 'Parallel initialization'
!$OMP PARALLEL DO
#else
      PRINT *, 'Sequential initialization'
#endif
      DO 10 j = 1,n
          a(j) = 2.0d0
          b(j) = 0.5D0
          c(j) = 0.0D0
   10 CONTINUE
      t = mysecond()
!$OMP PARALLEL DO
      DO 20 j = 1,n
          a(j) = 0.5d0*a(j)
   20 CONTINUE
      t = mysecond() - t
      PRINT *,'----------------------------------------------------'
      quantum = checktick()
      WRITE (*,FMT=9000)
     $  'Your clock granularity/precision appears to be ',quantum,
     $  ' microseconds'

      PRINT *,'----------------------------------------------------'
      readset = 1_8 * (REAL(STREAM_ARRAY_SIZE, 8) / REAL(gb, 8))
     $  * realsize
      writeset = 1_8 * (REAL(STREAM_ARRAY_SIZE, 8) / REAL(gb, 8))
     $  * realsize
#if DO_COPY
      WRITE (*, FMT=9005) readset, writeset, readset + writeset
#endif
#if DO_SCALE
      WRITE (*, FMT=9006) readset, writeset, readset + writeset
#endif
      readset = 2_8 * (REAL(STREAM_ARRAY_SIZE, 8) / REAL(gb, 8))
     $  * realsize
#if DO_ADD
      WRITE (*, FMT=9007) readset, writeset, readset + writeset
#endif
#if DO_TRIAD
      WRITE (*, FMT=9008) readset, writeset, readset + writeset
#endif

      PRINT *,'----------------------------------------------------'

*       --- MAIN LOOP --- repeat test cases NTIMES times ---
      scalar = 0.5d0*a(1)
      DO 70 k = 1,ntimes

#if DO_COPY
          t = mysecond()
          a(1) = a(1) + t
          CALL STREAM_copy(a, c, n)
          t = mysecond() - t
          c(n) = c(n) + t
          times(1,k) = t
#endif

#if DO_SCALE
          t = mysecond()
          c(1) = c(1) + t
          CALL STREAM_scale(b, c, scalar, n)
          t = mysecond() - t
          b(n) = b(n) + t
          times(2,k) = t
#endif

#if DO_ADD
          t = mysecond()
          a(1) = a(1) + t
          CALL STREAM_add(a, b, c, n)
          t = mysecond() - t
          c(n) = c(n) + t
          times(3,k) = t
#endif

#if DO_TRIAD
          t = mysecond()
          b(1) = b(1) + t
          CALL STREAM_triad(a, b, c, scalar, n)
          t = mysecond() - t
          a(n) = a(n) + t
          times(4,k) = t
#endif
   70 CONTINUE

*       --- SUMMARY ---
      DO 90 k = 2,ntimes
          DO 80 j = 1,4
              avgtime(j) = avgtime(j) + times(j,k)
              mintime(j) = min(mintime(j),times(j,k))
              maxtime(j) = max(maxtime(j),times(j,k))
   80     CONTINUE
   90 CONTINUE
      WRITE (*,FMT=9040)
      DO 100 j = 1,4
          IF (enabled(j).NE.0) then
              avgtime(j) = avgtime(j)/dble(ntimes-1)
              WRITE (*,FMT=9050) label(j),n*bytes(j)*nbpw/mintime(j)/
     $          1.0D6,
     $          avgtime(j),mintime(j),maxtime(j)
          END IF
  100 CONTINUE
      PRINT *,'----------------------------------------------------'
      CALL checksums (a,b,c,n,ntimes)
      PRINT *,'----------------------------------------------------'

 9000 FORMAT (1x,a,i6,a)
 9005 FORMAT (1x,'Copy:  ',f10.4,' GB read set, ',f10.4,
     $ ' GB write set', f10.4, ' GB total working set')
 9006 FORMAT (1x,'Scale: ',f10.4,' GB read set, ',f10.4,
     $ ' GB write set', f10.4, ' GB total working set')
 9007 FORMAT (1x,'Add:   ',f10.4,' GB read set, ',f10.4,
     $ ' GB write set', f10.4, ' GB total working set')
 9008 FORMAT (1x,'Triad: ',f10.4,' GB read set, ',f10.4,
     $ ' GB write set', f10.4, ' GB total working set')
 9010 FORMAT (1x,a,i10)
 9020 FORMAT (1x,a,i4,a)
 9030 FORMAT (1x,a,i3,a,a)
 9040 FORMAT (1x,'Function',5x,
     $ 'Rate (MB/s)       Avg time       Min time       Max time')
 9050 FORMAT (1x,a,4 (f13.4,2x))

      END PROGRAM stream


*-------------------------------------
* INTEGER(8) FUNCTION dblesize()
*
* A semi-portable way to determine the precision of DOUBLE PRECISION
* in Fortran.
* Here used to guess how many bytes of storage a DOUBLE PRECISION
* number occupies.
*
      SUBROUTINE confuse(q,r)
*     IMPLICIT NONE
C     .. Scalar Arguments ..
      DOUBLE PRECISION q,r
C     ..
C     .. Intrinsic Functions ..
      INTRINSIC cos
C     ..
      r = cos(q)
      RETURN
      END

* A semi-portable way to determine the clock granularity
* Adapted from a code by John Henning of Digital Equipment Corporation
*
      INTEGER(8) FUNCTION checktick()
*     IMPLICIT NONE

C     .. Parameters ..
      INTEGER(8) n
      PARAMETER (n=20)
C     ..
C     .. Local Scalars ..
      DOUBLE PRECISION t1,t2
      INTEGER(8) i,j,jmin
C     ..
C     .. Local Arrays ..
      DOUBLE PRECISION timesfound(n)
C     ..
C     .. External Functions ..
      DOUBLE PRECISION mysecond
      EXTERNAL mysecond
C     ..
C     .. Intrinsic Functions ..
      INTRINSIC max,min,nint
C     ..
      i = 0

   10 t2 = mysecond()
      IF (t2.EQ.t1) GO TO 10

      t1 = t2
      i = i + 1
      timesfound(i) = t1
      IF (i.LT.n) GO TO 10

      jmin = 1000000
      DO 20 i = 2,n
          j = nint((timesfound(i)-timesfound(i-1))*1d6)
          jmin = min(jmin,max(j,0))
   20 CONTINUE

      IF (jmin.GT.0) THEN
          checktick = jmin
      ELSE
          PRINT *,'Your clock granularity appears to be less ',
     $      'than one microsecond'
          checktick = 1
      END IF
      RETURN

*      PRINT 14, timesfound(1)*1d6
*      DO 20 i=2,n
*         PRINT 14, timesfound(i)*1d6,
*     &       nint((timesfound(i)-timesfound(i-1))*1d6)
*   14    FORMAT (1X, F18.4, 1X, i8)
*   20 CONTINUE

      END

      SUBROUTINE checksums(a,b,c,n,ntimes)
*     IMPLICIT NONE
C     ..
C     .. Arguments ..
      STREAM_TYPE a(*),b(*),c(*)
      INTEGER(8) n,ntimes
C     ..
C     .. Local Scalars ..
      DOUBLE PRECISION aa,bb,cc,scalar,suma,sumb,sumc,epsilon
      INTEGER(8) k
C     ..

C     Repeat the main loop, but with scalars only.
C     This is done to check the sum & make sure all
C     iterations have been executed correctly.

      aa = 2.0D0
      bb = 0.5D0
      cc = 0.0D0
      aa = 0.5D0*aa
      scalar = 0.5d0*aa
      DO k = 1,ntimes
#if DO_COPY
          cc = aa
#endif
#if DO_SCALE
          bb = scalar*cc
#endif
#if DO_ADD
          cc = aa + bb
#endif
#if DO_TRIAD
          aa = bb + scalar*cc
#endif
      END DO
      aa = aa*DBLE(n-2)
      bb = bb*DBLE(n-2)
      cc = cc*DBLE(n-2)

C     Now sum up the arrays, excluding the first and last
C     elements, which are modified using the timing results
C     to confuse aggressive optimizers.

      suma = 0.0d0
      sumb = 0.0d0
      sumc = 0.0d0
!$OMP PARALLEL DO REDUCTION(+:suma,sumb,sumc)
      DO 110 j = 2,n-1
          suma = suma + a(j)
          sumb = sumb + b(j)
          sumc = sumc + c(j)
  110 CONTINUE

      epsilon = 1.D-6

      IF (ABS(suma-aa)/suma .GT. epsilon) THEN
          PRINT *,'Failed Validation on array a()'
          PRINT *,'Target   Sum of a is = ',aa
          PRINT *,'Computed Sum of a is = ',suma
      ELSEIF (ABS(sumb-bb)/sumb .GT. epsilon) THEN
          PRINT *,'Failed Validation on array b()'
          PRINT *,'Target   Sum of b is = ',bb
          PRINT *,'Computed Sum of b is = ',sumb
      ELSEIF (ABS(sumc-cc)/sumc .GT. epsilon) THEN
          PRINT *,'Failed Validation on array c()'
          PRINT *,'Target   Sum of c is = ',cc
          PRINT *,'Computed Sum of c is = ',sumc
      ELSE
          PRINT *,'Solution Validates!'
      ENDIF

      END

#if DO_COPY
      SUBROUTINE STREAM_copy(a, c, n)
          IMPLICIT NONE
          STREAM_TYPE, DIMENSION(*) :: a, c
          INTEGER(8) :: n
          INTEGER(8) :: J
!$OMP PARALLEL DO
          DO 30 j = 1,n
              c(j) = a(j)
   30     CONTINUE
      END SUBROUTINE STREAM_copy
#endif

#if DO_SCALE
      SUBROUTINE STREAM_scale(b, c, scalar, n)
          IMPLICIT NONE
          STREAM_TYPE, DIMENSION(*) :: b, c
          STREAM_TYPE :: scalar
          INTEGER(8) :: n
          INTEGER(8) :: J
!$OMP PARALLEL DO
          DO 40 j = 1,n
              b(j) = scalar*c(j)
   40     CONTINUE
      END SUBROUTINE STREAM_scale
#endif

#if DO_ADD
      SUBROUTINE STREAM_add(a, b, c, n)
          IMPLICIT NONE
          STREAM_TYPE, DIMENSION(*) :: a, b, c
          INTEGER(8) :: n
          INTEGER(8) :: J
!$OMP PARALLEL DO
          DO 50 j = 1,n
              c(j) = a(j) + b(j)
   50     CONTINUE
      END SUBROUTINE STREAM_add
#endif

#if DO_TRIAD
      SUBROUTINE STREAM_triad(a, b, c, scalar, n)
          IMPLICIT NONE
          STREAM_TYPE, DIMENSION(*) :: a, b, c
          STREAM_TYPE :: scalar
          INTEGER(8) :: n
          INTEGER(8) :: J
!$OMP PARALLEL DO
          DO 60 j = 1,n
              a(j) = b(j) + scalar*c(j)
   60     CONTINUE
      END SUBROUTINE STREAM_triad
#endif

