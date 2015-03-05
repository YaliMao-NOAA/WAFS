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

       subroutine get_BiasData(biasgribfile,
     +    jmm,jdd,jhh,kk4,kk5,kk6,kk7,ngrid,bias)

      use grib_mod
      include 'parm.inc'
      
      type(gribfield) :: gfld                                                                                                                                
      dimension jpds(25),jgds(25),kpds(25),kgds(25),jjpds(25)          !grib
      real bias(ngrid)                                                                                                                                          
 
      character*80 biasgribfile
      integer biasgribunit


      biasgribunit=205

      write(*,*) ' In get_BiasData' 


       write(*,*) 'Observ time(MM,DD,HH) = ', jmm,jdd,jhh

       write(*,*) trim(biasgribfile)


       call baopen(biasgribunit,biasgribfile, ierr)
       if(ierr.ne.0) then
        write(*,*)'open ',trim(biasgribfile), ' error'
        stop 118
       end if

         jpd1=kk4
         jpd2=kk5
         jpd10=kk6
         jpd12=kk7
                                                                                                                                   
         jpds(9)=jmm
         jpds(10)=jdd
         jpds(11)=jhh

         call readGB2(biasgribunit,0,jpd1,jpd2,jpd10,jpd12,
     +      -1,jmm,jdd,jhh,-1,jf,gfld,iret)

          if(iret.ne.0) then
            write(*,*)'no bias data, iret=',iret  
            bias=0.0
          else
            bias=gfld%fld
          end if
               
        call baclose(biasgribunit, ierr)
 
                
        return
        end


