  subroutine sundry(hs,ps,km,pd,p,u,v,t,h,om,rh,sh,shs,o3,ct,&
                    kpo,po,hpo,kpt,pt,tpt,shpt,suns,sunu,sunv)
!$$$  Subprogram documentation block
!
! Subprogram: sundry     Compute sundry single-level posted fields
!   Prgmmr: Iredell      Org: np23        Date: 1999-10-18
!
! Abstract: This subprogram computes sundry single-level posted fields.
!   The fields returned are surface orography and pressure; tropopause wind,
!   temperature, height, and vertical shear; both surface and best lifted index,
!   convective available potential energy and convective inhibition; maximum
!   wind level wind, temperature, and height; sea level pressure; column
!   precipitable water and average relative humidities; bottom sigma fields;
!   and total ozone and total cloud water.
!
! Program history log:
!   1999-10-18  Mark Iredell
!
! Usage:  call sundry(hs,ps,km,pd,p,u,v,t,h,om,rh,sh,shs,o3,ct,&
!                     kpo,po,hpo,kpt,pt,tpt,shpt,suns,sunu,sunv)
!   Input argument list:
!     hs       real surface height (m)
!     ps       real surface pressure (Pa)
!     km       integer number of levels
!     pd       real (km) pressure thickness (Pa)
!     p        real (km) pressure (Pa)
!     u        real (km) x-component wind (m/s)
!     v        real (km) y-component wind (m/s)
!     t        real (km) temperature (K)
!     h        real (km) height (m)
!     om       real (km) vertical velocity (Pa/s)
!     rh       real (km) relative humidity (percent)
!     sh       real (km) specific humidity (kg/kg)
!     shs      real (km) saturation specific humidity (kg/kg)
!     o3       real (km) specific ozone (kg/kg)
!     ct       real (km) specific cloud water (kg/kg)
!     kpo      integer number of pressure levels
!     po       real (kpo) pressure levels (Pa)
!     hpo      real (kpo) height (m)
!     kpt      integer number of pressure layers
!     pt       real (kpt) pressure layer edges above surface (Pa)
!     tpt      real (kpt) temperature (K)
!     shpt     real (kpt) specific humidity (kg/kg)
!   Output argument list:
!     suns     real (nsuns) sundry scalar fields
!     sunu     real (nsunv) sundry vector x-component fields
!     sunv     real (nsunv) sundry vector y-component fields
!
! Modules used:
!   postgp_module  Shared data for postgp
!   funcphys       Physical functions
!
! Files included:
!   physcons.h     Physical constants
!
! Subprograms called:
!   tpause         compute tropopause level fields
!   liftix         compute lifting index, cape and cin
!   mxwind         compute maximum wind level fields
!   freeze         compute freezing level fields
!   rsearch1       search for a surrounding real interval
!
! Attributes:
!   Language: Fortran 90
!
!$$$
    use postgp_module
    use funcphys
    use physcons
    implicit none
    integer,intent(in):: km,kpo,kpt
    real,intent(in):: hs,ps
    real,intent(in),dimension(km):: pd,p,u,v,t,h,om,rh,sh,shs,o3,ct
    real,intent(in),dimension(kpo):: po,hpo
    real,intent(in),dimension(kpt):: pt,tpt,shpt
    real,intent(out):: suns(nsuns),sunu(nsunv),sunv(nsunv)
    real,parameter:: pslp(2)=(/1000.e+2,500.e+2/),&
                     pm1=1.e5,tm1=287.45,hm1=113.,hm2=5572.,&
                     fslp=con_g*(hm2-hm1)/(con_rd*tm1)
    real,parameter:: strh1=0.44,strh2=0.72,strh3=0.44,strh4=0.33,&
                     sbrh1=1.00,sbrh2=0.94,sbrh3=0.72,sbrh4=1.00
    real,parameter:: sl1=0.9950
    integer k,kslp(2)
    real sumtn,sumtd,sum1n,sum1d,sum2n,sum2d,sum3n,sum3d,sum4n,sum4d
    real pid,piu,dp1,dp2,dp3,dp4
    real sumo3,sumct,p1,p1k,f2
    real hfac
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  surface orography and surface pressure
    suns(isuns_hgt_sfc)=hs
    suns(isuns_pres_sfc)=ps
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  sundry tropopause fields
    call tpause(km,p,u,v,t,h,&
                suns(isuns_pres_trp),sunu(isunu_ugrd_trp),sunv(isunv_vgrd_trp),&
                suns(isuns_tmp_trp),suns(isuns_hgt_trp),suns(isuns_vwsh_trp))
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  lifted index, cape and cin
    call liftix(ps,kpt,pt,tpt,shpt,km,p,t,sh,h,&
                suns(isuns_lftx_sfc),suns(isuns_cape_sfc),suns(isuns_cin_sfc),&
                suns(isuns_blftx_sfc),&
                suns(isuns_cape_plg_180_0),suns(isuns_cin_plg_180_0))
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  sundry maxwind fields
    call mxwind(km,p,u,v,t,h,&
                suns(isuns_pres_mwl),sunu(isunu_ugrd_mwl),sunv(isunv_vgrd_mwl),&
                suns(isuns_tmp_mwl),suns(isuns_hgt_mwl))
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  sundry freezing fields
    call freeze(km,hs,p,t,h,rh,&
                suns(isuns_hgt_zdeg),suns(isuns_rh_zdeg),&
                suns(isuns_hgt_htfl),suns(isuns_rh_htfl))
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  sea level pressure
    call rsearch1(kpo,po(1),2,pslp(1),kslp(1))
    if(kslp(1).gt.0.and.po(kslp(1)).eq.pslp(1).and.&
       kslp(2).gt.0.and.po(kslp(2)).eq.pslp(2)) then
      hfac=hpo(kslp(1))/(hpo(kslp(2))-hpo(kslp(1)))
      suns(isuns_prmsl_msl)=pm1*exp(fslp*hfac)
    else
      suns(isuns_prmsl_msl)=0
    endif
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  column precipitable water and average relative humidities
    sumtn=0
    sumtd=0
    sum1n=0
    sum1d=0
    sum2n=0
    sum2d=0
    sum3n=0
    sum3d=0
    sum4n=0
    sum4d=0
    pid=ps
    do k=1,km
      sumtn=sumtn+sh(k)*pd(k)
      sumtd=sumtd+shs(k)*pd(k)
      piu=pid-pd(k)
      dp1=max(min(pid,sbrh1*ps)-max(piu,strh1*ps),0.)
      sum1n=sum1n+sh(k)*dp1
      sum1d=sum1d+shs(k)*dp1
      dp2=max(min(pid,sbrh2*ps)-max(piu,strh2*ps),0.)
      sum2n=sum2n+sh(k)*dp2
      sum2d=sum2d+shs(k)*dp2
      dp3=max(min(pid,sbrh3*ps)-max(piu,strh3*ps),0.)
      sum3n=sum3n+sh(k)*dp3
      sum3d=sum3d+shs(k)*dp3
      dp4=max(min(pid,sbrh4*ps)-max(piu,strh4*ps),0.)
      sum4n=sum4n+sh(k)*dp4
      sum4d=sum4d+shs(k)*dp4
      pid=piu
    enddo
    suns(isuns_pwat_clm)=max(sumtn,0.)/con_g
    suns(isuns_rh_clm)=1.e2*min(max(sumtn/sumtd,0.),1.)
    suns(isuns_rh_slr_044_100)=1.e2*min(max(sum1n/sum1d,0.),1.)
    suns(isuns_rh_slr_072_094)=1.e2*min(max(sum2n/sum2d,0.),1.)
    suns(isuns_rh_slr_044_072)=1.e2*min(max(sum3n/sum3d,0.),1.)
    suns(isuns_rh_slr_033_100)=1.e2*min(max(sum4n/sum4d,0.),1.)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  bottom sigma fields interpolated from first two model layers
    p1=sl1*ps
    f2=log(p(1)/p1)/log(p(1)/p(2))
    p1k=fpkap(real(p1,krealfp))
    suns(isuns_tmp_sig_9950)=t(1)+f2*(t(2)-t(1))
    suns(isuns_pot_sig_9950)=suns(isuns_tmp_sig_9950)/p1k
    suns(isuns_vvel_sig_9950)=om(1)+f2*(om(2)-om(1))
    suns(isuns_rh_sig_9950)=rh(1)+f2*(rh(2)-rh(1))
    sunu(isunu_ugrd_sig_9950)=u(1)+f2*(u(2)-u(1))
    sunv(isunv_vgrd_sig_9950)=v(1)+f2*(v(2)-v(1))
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  total ozone
    sumo3=0
    do k=1,km
      sumo3=sumo3+o3(k)*pd(k)
    enddo
!  convert ozone from kg/m2 to dobson units, which give the depth of the
!  ozone layer in 1e-5 m if brought to natural temperature and pressure.
    suns(isuns_tozne_clm)=max(sumo3,0.)/(con_g*2.14e-5)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  total cloud water
    sumct=0
    do k=1,km
      sumct=sumct+ct(k)*pd(k)
    enddo
    suns(isuns_cwat_clm)=max(sumct,0.)/con_g
  end subroutine
