        subroutine cvncep(f1,maxgrd,ilon,ilat)
! invert CMC data from north to south
!
        real   f1(maxgrd),f2(maxgrd)
! judge if all read in  data have the same format as NCEP GEFS
czhoub  if(kgds(4).eq.lgds(4).and.kgds(7).eq.lgds(7)) return
! invert forecast data from north to south

        do i = 1, ilon
        do j = 1, ilat
          ij=(j-1)*ilon + i
          ijcv=(ilat-j)*ilon + i
          f2(ijcv)=f1(ij)
        enddo
        enddo

        f1=f2

        return
        end

        subroutine debias(bias,f1,maxgrd)
!     apply the bias correction
!
!     parameters
!                  bias   ---> bias estimation

        integer maxgrd,ij
        real bias(maxgrd),f1(maxgrd)

        do ij=1,maxgrd
          if(f1(ij).gt.-99999.0.and.f1(ij).lt.999999.0.and.bias(ij).
     +     gt.-99999.0.and.bias(ij).lt.999999.0) then
            f1(ij)=f1(ij)-bias(ij)
          else
            f1(ij)=f1(ij)
          endif
        enddo

        return
        end

       subroutine get_BiasData(biasgribfile,biasindxfile,
     +    jmm,jdd,jhh,kk5,kk6,kk7,ngrid,bias)

      include 'parm.inc'
                                                                                                                                      
      dimension jpds(25),jgds(25),kpds(25),kgds(25),jjpds(25)          !grib
      logical, allocatable, dimension(:)  :: lb
      real bias(ngrid)                                                                                                                                          
 
      character*80 biasgribfile, biasindxfile
      integer biasgribunit, biasindxunit

      allocate(lb(ngrid))

      biasgribunit=205
      biasindxunit=206

      write(*,*) ' In get_BiasData' 


       write(*,*) 'Observ time(MM,DD,HH) = ', jmm,jdd,jhh

       write(*,*) trim(biasgribfile),' ',trim(biasindxfile)


       call baopen(biasgribunit,biasgribfile, ierr)
       if(ierr.ne.0) then
        write(*,*)'open ',trim(biasgribfile), ' error'
        stop 118
       end if

       call baopen(biasindxunit,biasindxfile, ierr)
       if(ierr.ne.0) then
        write(*,*) 'open ',trim(biasindxfile), ' error'
        stop 218
       end if


         jgds=-1
         jpds=-1
         kgds=-1
          
         jpds(5) = kk5
         jpds(6) = kk6
         jpds(7) = kk7
                                                                                                                                   
         jpds(9)=jmm
         jpds(10)=jdd
         jpds(11)=jhh

          call getgb(biasgribunit,biasindxunit,ngrid,0,jpds,jgds,
     &                      kf, k, kpds, kgds, lb, bias, iret)
          if(iret.ne.0) then
            write(*,*)'no bias data, iret=',iret  
            bias=0.0
          end if
               
        call baclose(biasgribunit, ierr)
        call baclose(biasindxunit, ierr)
 
          deallocate(lb)
                
        return
        end


