program pi

implicit none

include "mpif.h"

integer, parameter :: DARTS = 50000, ROUNDS = 10, MASTER = 0

real(8) :: pi_est
real(8) :: homepi, avepi, pirecv, pisum
integer :: rank, comm_size, mtype, ierr
integer :: i, n
integer, allocatable :: seed(:)
integer :: istatus(MPI_STATUS_SIZE)
integer :: mydarts,remainder

call MPI_Init(ierr)
call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
call MPI_Comm_size(MPI_COMM_WORLD, comm_size, ierr)

print *, "MPI task ", rank, " has started ..."

if (rank == MASTER) then
   print *, "Using ", comm_size, " tasks to compute pi (3.1415926535)"
end if

! initialize the random number generator
! we make sure the seed is different for each task
call random_seed()
call random_seed(size = n)
allocate(seed(n))
seed = 12 + rank*11
call random_seed(put=seed(1:n))
deallocate(seed)

avepi = 0
! split the darts for each round between the processes
mydarts=DARTS/comm_size
remainder=mod(DARTS,comm_size)
if(rank.lt.remainder) then
 mydarts=mydarts+1
endif

do i = 0, ROUNDS-1
   homepi = dboard(mydarts)

   if (rank /= MASTER) then
      mtype = i
      call MPI_Send(homepi,1,MPI_DOUBLE_PRECISION, MASTER, mtype, &
                    MPI_COMM_WORLD, ierr)
   else
      mtype = i
      pisum = 0
      do n = 1, comm_size-1
         call MPI_Recv(pirecv, 1, MPI_DOUBLE_PRECISION, MPI_ANY_SOURCE, &
                       mtype, MPI_COMM_WORLD, istatus, ierr)

         ! keep a running total of pi
         pisum = pisum + pirecv
      end do

      ! calculate the average value of pi for this iteration
      pi_est = (pisum + homepi)/comm_size

      ! calculate the average value of pi over all iterations
      avepi = ((avepi*i) + pi_est)/(i + 1)

      print *, "After ", DARTS*(i+1), " throws, average value of pi =", avepi

   end if
end do

call MPI_Finalize(ierr)

contains

   real(8) function dboard(darts)

      integer, intent(in) :: darts

      real(8) :: x_coord, y_coord
      integer :: score, n

      score = 0
      do n = 1, darts
         call random_number(x_coord)
         call random_number(y_coord)

         if ((x_coord**2 + y_coord**2) <= 1.0d0) then
            score = score + 1
         end if
      end do
      dboard = 4.0d0*score/darts

   end function

end program
