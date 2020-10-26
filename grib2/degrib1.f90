program degrib1

implicit none

! getgbh
integer :: jpds(200)=-1, jgds(200)=-1, kpds(200), kgds(200)
integer :: kg, kf, kk,iret
! getgb, adding more to getgbh
integer :: nx, ny, nxy
logical, allocatable :: bitmap(:,:)
real, allocatable :: dat(:,:)

! file name and unit
character(len=200) :: datafile
integer :: unit

! slat, only for grid 4
real, allocatable :: slat(:), mesh(:)
integer :: igrid=4

! do what you want
integer :: jpds5, jpds6
integer :: i, j, k

call GET_COMMAND_ARGUMENT(1, datafile)
unit = 16
call BAOPENR(unit, datafile, iret)
call getgbh(unit, 0, -1, jpds, jgds, kg, kf, kk, kpds, kgds, iret)

nx = kgds(2)
ny = kgds(3)
nxy = nx * ny

if(kgds(1) == igrid) then
  allocate(slat(ny))
  allocate(mesh(ny))
  call splat(4, 880, slat, mesh)
  write(*,*) slat
endif

write(*,*) "GDS, nx=", nx, " ny=", ny
do k=1, 25
  write(*,*) "k=", k, kgds(k)
end do
write(*,*) "PDS"
do k=1, 22
  write(*,*) "k=", k, kpds(k)
end do


call getgbh(unit, 0, -4, jpds, jgds, kg, kf, kk, kpds, kgds, iret)

nx = kgds(2)
ny = kgds(3)
nxy = nx * ny

if(kgds(1) == igrid) then
  allocate(slat(ny))
  allocate(mesh(ny))
  call splat(4, 880, slat, mesh)
  write(*,*) slat
endif

write(*,*) "GDS, nx=", nx, " ny=", ny
do k=1, 25
  write(*,*) "k=", k, kgds(k)
end do
write(*,*) "PDS"
do k=1, 22
  write(*,*) "k=", k, kpds(k)
end do

allocate(bitmap(nx, ny))
allocate(dat(nx, ny))

!=============================================
! do what you want -- start

!jpds5 = 171
!jpds6 = 100
!jpds(5) = jpds5
!jpds(6) = jpds6

!do k = 300, 700, 100
!  jpds(7) = k
!  call GETGB(unit, 0, nxy, 0, jpds, jgds, kf, kk, kpds, kgds, bitmap, dat, iret)
!enddo
! do what you want -- end
!=============================================


if(allocated(slat)) deallocate(slat)
if(allocated(mesh)) deallocate(mesh)

deallocate(bitmap)
deallocate(dat)

end program
 
