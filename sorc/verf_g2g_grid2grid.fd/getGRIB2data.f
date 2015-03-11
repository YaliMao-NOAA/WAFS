c 
c   This program is to read data from GRIB2 file
c   Author: Binbin Zhou
c           June 2014 , NOAA/NCEP/EMC
c


      subroutine getGRIB2data (grbunit,grib2file,data,u,v,
     +         levels,numfcst,numvarbl,numlevel,ngrid,
     +         yy,mm,dd,hh,ff,k4,k5,k6,k7,plevel,namvarbl,
     +         Nmodel,model)

      use grib_mod
      include 'parm.inc'

      integer numfcst,numvarbl,numlevel,ngrid   

      real var(ngrid),
     + data(numfcst,numvarbl,numlevel,ngrid),
     + u(numfcst,numvarbl,numlevel,ngrid),
     + v(numfcst,numvarbl,numlevel,ngrid)

      integer k5(mxvrbl),k6(mxvrbl),k7(mxvrbl),k4(mxvrbl)
      integer plevel(maxlvl)
      integer levels(mxvrbl)          !levels for different variables
      integer yy(mxfcst), mm(mxfcst), dd(mxfcst), hh(mxfcst), 
     +        ff(mxfcst),yyyy 
      CHARACTER*24 namvarbl(mxvrbl),model 
                                                                                                                                                    
      integer yyfcst(mxfcst),yyobsv(maxobs)


      integer grbunit

      integer nodata(mxfcst,mxvrbl,maxlvl)
      COMMON /nofile/nodata

      integer igribid
      COMMON /grb/igribid


      type(gribfield) :: gfld
      integer jpdtn,jpd1,jpd2,jpd10,jpd12
      CHARACTER*80 grib2file

      write(*,*)'In getGRIB2data:',grbunit,grib2file,ngrid

      call baopenr(grbunit, grib2file, ierr)
        write(*,*) 'open ', grib2file, ' ierr=',ierr

      do 500 nfcst = 1, numfcst

         write(*,*) 'Forecast time = ',  nfcst

       do 600 nvar = 1, numvarbl

         write(*,*) 'Variable#', nvar

         write(*,'(a16,5i4)') 'yy,mm,dd,hh,ff=',yy(nfcst),
     +    mm(nfcst),dd(nfcst),hh(nfcst),ff(nfcst) 

        !jpdtn=-1            !Templete# wildcard has problem? repeat  read one field
        if (Nmodel.eq.1) then 
          jpdtn=0            !Product Templete# non-ensemble
        else if (Nmodel.gt.1.and.grib2file(1:4).eq.'obsv') then
          jpdtn=0
        else if (Nmodel.gt.1.and.grib2file(1:4).eq.'fcst') then
          if(model(1:4).eq.'sref') then
           jpdtn=0
          else
           jpdtn=1
          end if
        else
          write(*,*) "Check Product Template# in this grib2 file!"
          STOP 333
        end if


        jpd1=k4(nvar)      !Category #
        jpd2=k5(nvar)      !Product # under this category
        jpd10=k6(nvar)     !Product vertical ID 
        jpd9=ff(nfcst)     !Forecast time or accumulation beginning time
                           
        if(jpd1.eq.16.and.jpd2.eq.196.and.
     +    trim(grib2file).eq.'fcst.grib.HRRR') jpd10=10        !for HRRR' composite reflectivity

        if(jpd1.eq.16.and.jpd2.eq.197.and.              !HRRR etop use non-standard product id
     +     trim(grib2file).eq.'fcst.grib.HRRR') then
          jpd1=16
          jpd2=3
          jpd10=3
        end if 

        if(jpd1.eq.6.and.jpd2.eq.1.and.              !HRRR total cloud  use non-standard product id
     +     grib2file(1:14).eq.'fcst.grib.HRRR') then
          jpd10=10
        end if


        if(jpd1.eq.6.and.jpd2.eq.1.and.
     +     grib2file(1:13).eq.'fcst.grib.GFS') then
           jpd10=10                 !GFS total cloud jpd10 changed from 200 to 10 in i2015 new GFS
           jpdtn=8
           jpd9=ff(nfcst)-6         !GFS total cloud is 6 hour accumulated using Template 4.8. 
                                    !jpd9 is accumuation beginning time(= orecast time - interval 6) 
        end if  

        if ( grib2file(1:13).eq.'fcst.grib.NAR'.or.
     +       grib2file(1:13).eq.'fcst.grib.SRE' ) then   ! NARREMEAN/SREFMEAN  uses Template 4.2
           jpdtn=2 
        end if
  

        jp =  jpd10                                   !Binbin: these 2 lines are used to
        if(jpd10.eq.100.or.jpd10.eq.104) jp=100   !deal with both jpds=100 and jpds=104(sigma level)

        if (jp.eq.100) then
          levels(nvar) = numlevel
        else
          levels(nvar) = 1
        end if

        yyyy=yy(nfcst)+2000
 
        if(jpd1.eq.2.and.jpd2.eq.1) then         !Wind 

          do np = 1, levels(nvar)

            if (jp.eq.100) then
              jpd12 = plevel(np)
            else
              jpd12 = k7(nvar)
            end if

        write(*,*) 'Var for ', jpd1,jpd2,jpd10,jpd12

           call readGB2(grbunit,jpdtn,2,2,jpd10,jpd12,yyyy,
     +      mm(nfcst),dd(nfcst),hh(nfcst),jpd9,ngrid,gfld,iret)


            if(iret.ne.0) then
              u(nfcst,nvar,np,:) = - 1.0E9
              nodata(nfcst,nvar,np) = 1
              write(*,*) '   read u error=',iret
            else
              u(nfcst,nvar,np,:)=gfld%fld(:)
            end if

           call readGB2(grbunit,jpdtn,2,3,jpd10,jpd12,yyyy,
     +      mm(nfcst),dd(nfcst),hh(nfcst),jpd9,ngrid,gfld,iret)
          
            if(iret.ne.0) then
              v(nfcst,nvar,np,:) = - 1.0E9
              nodata(nfcst,nvar,np) = 1
              write(*,*) '   read u error=',iret
            else
              v(nfcst,nvar,np,:)=gfld%fld(:)
            end if
 
 
              data(nfcst,nvar,np,:) = sqrt(
     &           u(nfcst,nvar,np,:)*u(nfcst,nvar,np,:)+
     &           v(nfcst,nvar,np,:)*v(nfcst,nvar,np,:) )
 
          end do
  
        else                    !Non-wind

          do np = 1, levels(nvar)

            if (jp.eq.100) then
              jpd12 = plevel(np)
            else
              jpd12 = k7(nvar)
            end if
 
        if(jpd1.eq.16.and.jpd2.eq.195.and.jpd10.eq.103.and.
     +              grib2file(1:4).eq.'obsv')    then    !for verifying 1000m reflectivity against MOSAIC's hybrid scan reflectivity (hrs) 
           jpd1=15
           jpd2=15
           jpd10=200
           jpd12 =0
        end if

        write(*,*) 'Var for ', jpdtn, jpd1,jpd2,jpd10,jpd12
        write(*,*) 'yyyy mm dd hh ff=', yyyy,mm(nfcst),dd(nfcst),
     +     hh(nfcst),ff(nfcst)

           call readGB2(grbunit,jpdtn,jpd1,jpd2,jpd10,jpd12,yyyy,
     +      mm(nfcst),dd(nfcst),hh(nfcst),jpd9,ngrid,gfld,iret)


            if(iret.ne.0) then
              data(nfcst,nvar,np,:) = - 1.0E9
              nodata(nfcst,nvar,np) = 1
              write(*,*) '   read error=',iret,'for ',jpd1,jpd2
            else
              data(nfcst,nvar,np,:)=gfld%fld(:)
            end if

          end do

        end if       

 600    continue
500   continue

       call baclose(grbunit,ierr)
       write(*,*) 'close ', grib2file, 'ierr=',ierr

      return
      end

        


      
