#!/bin/ksh 
########################################################################################################
#
#  prepg2g.sh is the script to prepare g2g verification, doing following steps 
#       after read in user-defined control file: 
#      (1) Check verification types:      
#          case 1: one verification data to verify multiple cycles of previous forecast
#          case 2: one cycle forecast verified by different verification data at different lead time
#      (2) According to the verification type (case 1 or case 2), 
#           (i)  construct the forecast and observation file names according to filename formats set by user
#           (ii) construct the forecast-verification time-macth pair for all forecast times 
#                and store them into a temp file g2g.ctl
#      (3) Saerch GRIB files for both regular variables and tendency variables. Tendency 
#          computation (3hr, 6hr, 12hr and 24hr) needs GRIB files previous 3, 6, 12, 24 hour before 
#      (4) Thin the GRIB files and concatenate all forecast GRIB into one GRIB file and all
#          verification GRIB files into one GRIB file
#      (5) If Wind speed is specified in the control, then also grab its U and V components
#      (6) Save all headers of user-defined parameters into g2g.ctl
#
#    usage: prepg2g.sh < user-defined control file
#
#    Author: Binbin Zhou, NCEP/EMC
#            Feb, 2005
#    
#  Note:   
#  NCEP model output filenames have such form as
#
#       fhead.tnnz.fgrbtype.fhh.ftm  (e.g. nam.t06z.awphys.f15.tm0, nam.t06z.awip32.f15.tm0)
#
#  So,  observation data files names are also re-named(if necessary) to similer format
#
#########################################################################################################
set -x

wgrb=${wgrb:-/nwprod/util/exec}
gribindex=${gribindex:-/nwprod/util/exec/grbindex}

cp $PARMverf_g2g/verf_g2g.grid104 grid#104
cp $PARMverf_g2g/verf_g2g.regions regions

rm -f g2g.ctl

# Specify the tendency buttons and cloud base/top care here:
export tnd03=${tnd03:-'close'}
export tnd06=${tnd06:-'close'}
export tnd12=${tnd12:-'close'}
export tnd24=${tnd24:-'close'}
export cloud_base_from_sfc=${cloud_base_from_sfc:-"no"}
export lat_weight=${lat_weight:-"no"}

# Now begin to read user-control file #########################################################

 read LINE                     #Header 1
  echo $LINE >> g2g.ctl
 read LINE                     #Header 2
  echo $LINE >> g2g.ctl
  set -A mdl $LINE
  model=${mdl[1]}
  echo "model="$model

# Check case type #############################################################################
 read LINE                     #Header 3
   set -A tfcst $LINE                                                 
   if [ ${tfcst[1]} -gt 2000000000 ] ; then    #if is case2:diff lead times from 1 forecast cycle vs diff verified data
     fcst[0]=${tfcst[1]}
   else                                        #if is case1:one verified data vs different previous cycle forecasts
     f[0]=${tfcst[1]}                           #cycle
     t=1
     while [ $t -lt ${tfcst[0]} ]
      do 
       read LINE
       f[$t]=$LINE                              #cycle
       t=`echo "$t + 1" | bc`
      done
   fi

# Construct forecast and observation file names for different cases (1 or 2) #####################
# and form tendency file pairs

 read LINE                     #Header 4
   set -A tobsv $LINE

   echo verification time: ${tobsv[1]}
  
   if [ ${tobsv[1]} -gt 2000000000 ] ; then    #case1:one verified data  vs different previous cycle forecasts
     cas=1
     obsv[0]=${tobsv[1]}
     oday[0]=`echo ${obsv[0]} | cut -c 1-8`
     obsv03[0]=`/nwprod/util/exec/ndate -3 ${obsv[0]}`
     oday03[0]=`echo ${obsv03[0]} | cut -c 1-8`
     obsv06[0]=`/nwprod/util/exec/ndate -6 ${obsv[0]}`
     oday06[0]=`echo ${obsv06[0]} | cut -c 1-8`
     obsv12[0]=`/nwprod/util/exec/ndate -12 ${obsv[0]}`
     oday12[0]=`echo ${obsv12[0]} | cut -c 1-8`
     obsv24[0]=`/nwprod/util/exec/ndate -24 ${obsv[0]}`
     oday24[0]=`echo ${obsv24[0]} | cut -c 1-8`

     to=`echo ${obsv[0]} | cut -c 9-10`                           #obsv cycle
     to03=`echo ${obsv03[0]} | cut -c 9-10`                       #obsv cycle for presious 12 hr
     to06=`echo ${obsv06[0]} | cut -c 9-10`                       #obsv cycle for presious 12 hr
     to12=`echo ${obsv12[0]} | cut -c 9-10`                       #obsv cycle for presious 12 hr
     to24=`echo ${obsv24[0]} | cut -c 9-10`                       #obsv cycle for presious 12 hr

     fileobsv[0]=$obsvdir.${oday[0]}/$ohead.t${to}z.${ogrbtype}${otail}$otm
     fileobsv03[0]=$obsvdir.${oday03[0]}/$ohead.t${to03}z.${ogrbtype}${otail}$otm
     fileobsv06[0]=$obsvdir.${oday06[0]}/$ohead.t${to06}z.${ogrbtype}${otail}$otm
     fileobsv12[0]=$obsvdir.${oday12[0]}/$ohead.t${to12}z.${ogrbtype}${otail}$otm
     fileobsv24[0]=$obsvdir.${oday24[0]}/$ohead.t${to24}z.${ogrbtype}${otail}$otm

     echo fileobsv[0]=${fileobsv[0]}

     nt=`expr $t - 1`  #     nt=total # of fcst times, ie ${tfcst[0]}
     t=0
     echo ${tfcst[0]}"  "forecasts:Ovservations >> g2g.ctl    
     while [ $t -le $nt ]
     do
       pass=` /nwprod/util/exec/ndate -${f[$t]} ${obsv[0]}`
       fday[$t]=`echo ${pass} | cut -c 1-8`
       fcst[$t]=$pass
       tf=`echo ${pass} | cut -c 9-10`                                    #fcst cycle


       if [ ${f[$t]} -lt 10 ] ; then
         f[$t]='0'${f[$t]}
       fi
       filefcst[$t]=$fcstdir.${fday[$t]}/$fhead.t${tf}z.${fgrbtype}${f[$t]}$ftm

       echo filefcst[$t]=${filefcst[$t]}

                                                                                                                                          
       f03[$t]=`expr ${f[$t]} - 3`
       f06[$t]=`expr ${f[$t]} - 6`
       f12[$t]=`expr ${f[$t]} - 12`
       f24[$t]=`expr ${f[$t]} - 24`


       if [ ${f03[$t]} -lt 0 ] ; then
        f03[$t]='NN'
       elif [ ${f03[$t]} -ge 0 ] && [ ${f03[$t]} -lt 10 ] ; then
        f03[$t]='0'${f03[$t]}
       fi

       if [ ${f06[$t]} -lt 0 ] ; then
        f06[$t]='NN'
       elif [ ${f06[$t]} -ge 0 ] && [ ${f06[$t]} -lt 10 ] ; then
        f06[$t]='0'${f06[$t]}
       fi

       if [ ${f12[$t]} -lt 0 ] ; then
        f12[$t]='NN'
       elif [ ${f12[$t]} -ge 0 ] && [ ${f12[$t]} -lt 10 ] ; then
        f12[$t]='0'${f12[$t]}
       fi

       if [ ${f24[$t]} -lt 0 ] ; then
        f24[$t]='NN'
       elif [ ${f24[$t]} -ge 0 ] && [ ${f24[$t]} -lt 10 ] ; then
        f24[$t]='0'${f24[$t]}
       fi


       filefcst03[$t]=$fcstdir.${fday[$t]}/$fhead.t${tf}z.${fgrbtype}${f03[$t]}$ftm
       filefcst06[$t]=$fcstdir.${fday[$t]}/$fhead.t${tf}z.${fgrbtype}${f06[$t]}$ftm
       filefcst12[$t]=$fcstdir.${fday[$t]}/$fhead.t${tf}z.${fgrbtype}${f12[$t]}$ftm
       filefcst24[$t]=$fcstdir.${fday[$t]}/$fhead.t${tf}z.${fgrbtype}${f24[$t]}$ftm


       if [ -s ${filefcst[$t]} ] ; then
         echo ${fday[$t]}${tf}${f[$t]}" "${oday[0]}${to}00" "${fday[$t]}${tf}${f03[$t]}" "${oday03[0]}${to03}00" "${fday[$t]}${tf}${f06[$t]}" "${oday06[0]}${to06}00" "${fday[$t]}${tf}${f12[$t]}" "${oday12[0]}${to12}00" "${fday[$t]}${tf}${f24[$t]}" "${oday24[0]}${to24}00 >> g2g.ctl
       else
         echo forecast files: ${filefcst[$t]}  not exist
          echo ${fday[$t]}${tf}${f[$t]}" "${oday[0]}${to}00" "${fday[$t]}${tf}${f03[$t]}" "${oday03[0]}${to03}00" "${fday[$t]}${tf}${f06[$t]}" "${oday06[0]}${to06}00" "${fday[$t]}${tf}${f12[$t]}" "${oday12[0]}${to12}00" "${fday[$t]}${tf}${f24[$t]}" "${oday24[0]}${to24}00 >> g2g.ctl
#         rm -f g2g.ctl
#         exit
       fi
        t=`expr $t + 1`
     done

   else                   #case2:diff lead times from one forecast  vs diferent later-on verified data
     cas=2
     fday[0]=`echo ${fcst[0]} | cut -c 1-8`
     tf=`echo ${fcst[0]} | cut -c 9-10`      #fcst cycle

     b[0]=${tobsv[1]}

     b03[0]=`expr ${b[0]} - 03`
     b06[0]=`expr ${b[0]} - 06`
     b12[0]=`expr ${b[0]} - 12`
     b24[0]=`expr ${b[0]} - 24`

     if [ b03[0] -lt 0 ] ; then
       b03[0]='NN'
     elif [ b03[0] -ge 0 ] && [ b03[0] -lt 10 ]; then
       b03[0]='0'${b03[0]}
     fi

     if [ b06[0] -lt 0 ] ; then
       b06[0]='NN'
     elif [ b06[0] -ge 0 ] && [ b06[0] -lt 10 ]; then
       b06[0]='0'${b06[0]}
     fi

     if [ b12[0] -lt 0 ] ; then
       b12[0]='NN'
     elif [ b12[0] -ge 0 ] && [ b12[0] -lt 10 ]; then
       b12[0]='0'${b12[0]}
     fi

     if [ b24[0] -lt 0 ] ; then
       b24[0]='NN'
     elif [ b24[0] -ge 0 ] && [ b24[0] -lt 10 ]; then
       b24[0]='0'${b24[0]}
     fi


     pass=`/nwprod/util/exec/ndate +${b[0]} ${fcst[0]}`
     pass03=`/nwprod/util/exec/ndate -3 $pass`
     pass06=`/nwprod/util/exec/ndate -6 $pass`
     pass12=`/nwprod/util/exec/ndate -12 $pass`
     pass24=`/nwprod/util/exec/ndate -24 $pass`

     oday[0]=`echo ${pass} | cut -c 1-8`
     obsv[0]=$pass
     oday03[0]=`echo ${pass03} | cut -c 1-8`  #observed day
     obsv03[0]=$pass03                        #observed time(valid time)
     oday06[0]=`echo ${pass06} | cut -c 1-8`  #observed day
     obsv06[0]=$pass06                        #observed time(valid time)
     oday12[0]=`echo ${pass12} | cut -c 1-8`  #observed day
     obsv12[0]=$pass12                        #observed time(valid time)
     oday24[0]=`echo ${pass24} | cut -c 1-8`  #observed day
     obsv24[0]=$pass24                        #observed time(valid time)

     if [ b[0] -lt 10 ] ; then
       b[0]='0'${b[0]}
     fi

     to=`echo ${pass} | cut -c 9-10`       #obsv cycle 
     filefcst[0]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b[0]}$ftm
     fileobsv[0]=$obsvdir.${oday[0]}/$ohead.t${to}z.${ogrbtype}${otail}$otm

     to03=`echo ${pass03} | cut -c 9-10`   #obsv cycle
     filefcst03[0]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b03[0]}$ftm
     fileobsv03[0]=$obsvdir.${oday03[0]}/$ohead.t${to03}z.${ogrbtype}${otail}$otm
     to06=`echo ${pass06} | cut -c 9-10`   #obsv cycle
     filefcst06[0]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b06[0]}$ftm
     fileobsv06[0]=$obsvdir.${oday06[0]}/$ohead.t${to06}z.${ogrbtype}${otail}$otm
     to12=`echo ${pass12} | cut -c 9-10`   #obsv cycle
     filefcst12[0]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b12[0]}$ftm
     fileobsv12[0]=$obsvdir.${oday12[0]}/$ohead.t${to12}z.${ogrbtype}${otail}$otm
     to24=`echo ${pass24} | cut -c 9-10`   #obsv cycle
     filefcst24[0]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b24[0]}$ftm
     fileobsv24[0]=$obsvdir.${oday24[0]}/$ohead.t${to24}z.${ogrbtype}${otail}$otm



     if [ -s ${filefcst[0]} ] && [ -s ${fileobsv[0]} ] ; then
         echo ${tobsv[0]}"  "forecasts~Ovservations >> g2g.ctl
         echo ${fday[0]}${tf}${b[0]}" "${oday[0]}${to}00" "${fday[0]}${tf}${b03[0]}" "${oday03[0]}${to03}00" "${fday[0]}${tf}${b06[0]}" "${oday06[0]}${to06}00" "${fday[0]}${tf}${b12[0]}" "${oday12[0]}${to12}00" "${fday[0]}${tf}${b24[0]}" "${oday24[0]}${to24}00 >> g2g.ctl
     else
         echo ${filefcst[0]} or ${fileobsv[0]} not exist
echo ${fday[0]}${tf}${b[0]}" "${oday[0]}${to}00" "${fday[0]}${tf}${b03[0]}" "${oday03[0]}${to03}00" "${fday[0]}${tf}${b06[0]}" "${oday06[0]}${to06}00" "${fday[0]}${tf}${b12[0]}" "${oday12[0]}${to12}00" "${fday[0]}${tf}${b24[0]}" "${oday24[0]}${to24}00 >> g2g.ctl
#         rm -f g2g.ctl
#         exit
     fi

     t=1
     while [ $t -lt ${tobsv[0]} ]
      do
       read LINE
       b[$t]=$LINE
       b03[$t]=`expr ${b[$t]} - 3`
       b06[$t]=`expr ${b[$t]} - 6`
       b12[$t]=`expr ${b[$t]} - 12`
       b24[$t]=`expr ${b[$t]} - 24`

       if [ ${b03[$t]} -lt 0 ] ; then
         b03[$t]='NN'
       elif [ ${b03[$t]} -ge 0 ] && [ ${b03[$t]} -lt 10 ] ; then
        b03[$t]='0'${b03[$t]} 
       fi

       if [ ${b06[$t]} -lt 0 ] ; then
         b06[$t]='NN'
       elif [ ${b06[$t]} -ge 0 ] && [ ${b06[$t]} -lt 10 ] ; then
        b06[$t]='0'${b06[$t]}
       fi

       if [ ${b12[$t]} -lt 0 ] ; then
         b12[$t]='NN'
       elif [ ${b12[$t]} -ge 0 ] && [ ${b12[$t]} -lt 10 ] ; then
        b12[$t]='0'${b12[$t]}
       fi

       if [ ${b24[$t]} -lt 0 ] ; then
         b24[$t]='NN'
       elif [ ${b24[$t]} -ge 0 ] && [ ${b24[$t]} -lt 10 ] ; then
        b24[$t]='0'${b24[$t]}
       fi


       pass=`/nwprod/util/exec/ndate +${b[$t]} ${fcst[0]}`
       pass03=`/nwprod/util/exec/ndate -3 $pass`
       pass06=`/nwprod/util/exec/ndate -6 $pass`
       pass12=`/nwprod/util/exec/ndate -12 $pass`
       pass24=`/nwprod/util/exec/ndate -24 $pass`

       oday[$t]=`echo ${pass} | cut -c 1-8`
       obsv[$t]=$pass 
       oday03[$t]=`echo ${pass03} | cut -c 1-8`
       obsv03[$t]=$pass03
       oday06[$t]=`echo ${pass06} | cut -c 1-8`
       obsv06[$t]=$pass06
       oday12[$t]=`echo ${pass12} | cut -c 1-8`
       obsv12[$t]=$pass12
       oday24[$t]=`echo ${pass24} | cut -c 1-8`
       obsv24[$t]=$pass24

       if [ b[$t] -lt 10 ] ; then
         b[$t]='0'${b[$t]}
       fi

       to=`echo ${pass} | cut -c 9-10`
       filefcst[$t]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b[$t]}$ftm
       fileobsv[$t]=$obsvdir.${oday[$t]}/$ohead.t${to}z.${ogrbtype}${otail}$otm

       to03=`echo ${pass03} | cut -c 9-10`
       filefcst03[$t]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b03[$t]}$ftm
       fileobsv03[$t]=$obsvdir.${oday03[$t]}/$ohead.t${to03}z.${ogrbtype}${otail}$otm
       to06=`echo ${pass06} | cut -c 9-10`
       filefcst06[$t]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b06[$t]}$ftm
       fileobsv06[$t]=$obsvdir.${oday06[$t]}/$ohead.t${to06}z.${ogrbtype}${otail}$otm
       to12=`echo ${pass12} | cut -c 9-10`
       filefcst12[$t]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b12[$t]}$ftm
       fileobsv12[$t]=$obsvdir.${oday12[$t]}/$ohead.t${to12}z.${ogrbtype}${otail}$otm
       to24=`echo ${pass24} | cut -c 9-10`
       filefcst24[$t]=$fcstdir.${fday[0]}/$fhead.t${tf}z.${fgrbtype}${b24[$t]}$ftm
       fileobsv24[$t]=$obsvdir.${oday24[$t]}/$ohead.t${to24}z.${ogrbtype}${otail}$otm


       if [ -s ${filefcst[$t]} ] && [ -s ${fileobsv[$t]} ] ; then
         echo ${fday[0]}${tf}${b[$t]}" "${oday[$t]}${to}00" "${fday[0]}${tf}${b03[$t]}" "${oday03[$t]}${to03}00" "${fday[0]}${tf}${b06[$t]}" "${oday06[$t]}${to06}00" "${fday[0]}${tf}${b12[$t]}" "${oday12[$t]}${to12}00" "${fday[0]}${tf}${b24[$t]}" "${oday24[$t]}${to24}00 >> g2g.ctl
       else
         echo ${filefcst[$t]} or ${fileobsv[$t]} not exist
echo ${fday[0]}${tf}${b[$t]}" "${oday[$t]}${to}00" "${fday[0]}${tf}${b03[$t]}" "${oday03[$t]}${to03}00" "${fday[0]}${tf}${b06[$t]}" "${oday06[$t]}${to06}00" "${fday[0]}${tf}${b12[$t]}" "${oday12[$t]}${to12}00" "${fday[0]}${tf}${b24[$t]}" "${oday24[$t]}${to24}00 >> g2g.ctl
#         rm -f g2g.ctl
#         exit
       fi

       t=`expr $t + 1`
      done
   fi


 read LINE                     #Header 5
   echo $LINE >> g2g.ctl
   set -A obtyp $LINE
   loop=${obtyp[0]}
   obsrvtype=${obtyp[1]}
   echo obsrvtype=$obsrvtype
   while [ $loop -gt 1 ]
    do
     read LINE
     echo $LINE >> g2g.ctl
     loop=`expr $loop - 1`
   done

 read LINE                     #Header 6
   echo $LINE >> g2g.ctl
   set -A grdtyp $LINE
   loop=${grdtyp[0]}
   while [ $loop -gt 1 ]
    do
     read LINE
     echo $LINE >> g2g.ctl
     loop=`expr $loop - 1`
   done  

 read LINE                    #Header 7
   echo $LINE >> g2g.ctl
   set -A statyp $LINE
   loop=${statyp[0]}
   while [ $loop -gt 1 ]
    do
     read LINE
     echo $LINE >> g2g.ctl
     loop=`expr $loop - 1`
   done

 read LINE                   #Header 8
   set -A var $LINE
   k5[0]=${var[2]}
   k6[0]=${var[3]}
   k7[0]=${var[4]}

   echo $LINE >> g2g.ctl

   loop=1
   nvar=${var[0]}
   while [ $loop -lt $nvar ]
    do
     read LINE
     set -A var $LINE
     k5[$loop]=${var[1]}
     k6[$loop]=${var[2]}
     k7[$loop]=${var[3]}
     if [ ${k5[$loop]} -eq 0 ] ; then
       echo $LINE not exist
       exit
     fi
     echo $LINE  >> g2g.ctl
     loop=`expr $loop + 1`
   done


# Begin to thin the GRIB files #############################################################################################

   rm -f obsv.grib fcst.grib obsv03.grib fcst03.grib obsv06.grib fcst06.grib obsv12.grib fcst12.grib obsv24.grib fcst24.grib
   rm -f obsv.indx fcst.indx obsv03.indx fcst03.indx obsv06.indx fcst06.indx obsv12.indx fcst12.indx obsv24.indx fcst24.indx

   varslp=0

   echo CASE $cas Model: $model 

   if [ $model = 'GFS' ] || [ $model = 'GFS_212' ] ; then
    accumufcst="TR="
    accumuobsv="TR="
   elif [ $model = 'HYSPLIT' ] ; then
    accumufcst="TR=3:"
    accumuobsv="TR=0:"
   elif [ $model = 'CMAQ' ] ; then
    accumufcst="TR=3:"
    accumuobsv="TR=0:"
   else
    accumufcst="TR=0:"
    accumuobsv="TR=0:"
   fi

   if [ $obsrvtype = 'RTMA' ] || [ $obsrvtype = 'AWC' ] ; then
     accumufcst="TR="
     accumuobsv="TR";
   fi
 

   echo "BEGIN to wgrib files ............................................"

   if [ $cas -eq 1 ] ; then                  # case 1

    echo CASE  1  : One verification time vs diff cycles of  forecasts

     varslp=0
     while [ $varslp -lt $nvar ]             # for all variables
      do
       if [ ${k5[$varslp]} -ne 32 ] ; then   # skip wind vector  
         kpds="kpds5="${k5[$varslp]}":kpds6="${k6[$varslp]}
         echo $kpds

         # for WAFS SADIS's CAT an Icing 
         if [ ${k5[$varslp]} -eq 168 ] ;   then     # SADIS's CAT
            accumufcst="TR=0:"
            accumuobsv="TR=1:"
         elif [ ${k5[$varslp]} -eq 172 ] ; then     # SADIS's icing potential
            accumufcst="TR=0:"
            accumuobsv="TR=0:"
         fi

         echo  wgribing ${fileobsv[0]} .........

         $wgrb/wgrib ${fileobsv[0]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv[0]} -o x  
         cat x >>obsv.grib
         
         echo "CHECK HERE !!!!"
          
         if [ $tnd03 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv03[0]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv03[0]} -o x
          cat x >>obsv03.grib
         fi

         if [ $tnd06 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv06[0]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv06[0]} -o x
          cat x >>obsv06.grib
         fi

         if [ $tnd12 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv12[0]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv12[0]} -o x
          cat x >>obsv12.grib
         fi

         if [ $tnd24 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv24[0]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv24[0]} -o x
          cat x >>obsv24.grib
         fi

         timelp=0
         while [ $timelp -lt ${tfcst[0]} ] # for all previous forecast cycles
          do  

          echo  wgribing ${filefcst[$timelp]} .......

          $wgrb/wgrib ${filefcst[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib  ${filefcst[$timelp]} -o y
          cat y >>fcst.grib 

          if [ -s ${filefcst03[$timelp]} ] && [ $tnd03 = 'open' ] ; then
            $wgrb/wgrib ${filefcst03[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib  ${filefcst03[$timelp]} -o y
            cat y >>fcst03.grib
          fi
          if [ -s ${filefcst06[$timelp]} ] && [ $tnd06 = 'open' ] ; then
            $wgrb/wgrib ${filefcst06[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib  ${filefcst06[$timelp]} -o y
            cat y >>fcst06.grib
          fi
          if [ -s ${filefcst12[$timelp]} ] && [ $tnd12 = 'open' ] ; then
            $wgrb/wgrib ${filefcst12[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib  ${filefcst12[$timelp]} -o y
            cat y >>fcst12.grib
          fi
          if [ -s ${filefcst24[$timelp]} ] && [ $tnd24 = 'open' ] ; then
            $wgrb/wgrib ${filefcst24[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib  ${filefcst24[$timelp]} -o y
            cat y >>fcst24.grib
          fi

          timelp=`expr $timelp + 1` 
         done
       fi
       varslp=`expr $varslp + 1`
     done

       nvar_1=`expr $nvar - 1`

      if [ ${k5[$nvar_1]} -eq 32 ] ; then  #if vector wind is specfied, must specifiy U and V (no matter if U or V are also spcified
         $wgrb/wgrib ${fileobsv[0]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv[0]} -o x
         cat x >>obsv.grib

         # for tendency case:
         if [ $tnd03 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv03[0]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv03[0]} -o x
          cat x >>obsv03.grib
         fi
         if [ $tnd06 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv06[0]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv06[0]} -o x
          cat x >>obsv06.grib
         fi
         if [ $tnd12 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv12[0]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv12[0]} -o x
          cat x >>obsv12.grib
         fi
         if [ $tnd24 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv24[0]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv24[0]} -o x
          cat x >>obsv24.grib
         fi

         $wgrb/wgrib ${fileobsv[0]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv[0]} -o x
         cat x >>obsv.grib

         if [ $tnd03 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv03[0]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv03[0]} -o x
          cat x >>obsv03.grib
         fi
         if [ $tnd06 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv06[0]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv06[0]} -o x
          cat x >>obsv06.grib
         fi
         if [ $tnd12 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv12[0]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv12[0]} -o x
          cat x >>obsv12.grib
         fi
         if [ $tnd24 = 'open' ] ; then
          $wgrb/wgrib ${fileobsv24[0]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv24[0]} -o x
          cat x >>obsv24.grib
         fi

         timelp=0
         while [ $timelp -lt ${tfcst[0]} ] # for all previous forecast cycles
         do
           $wgrb/wgrib ${filefcst[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[$timelp]} -o y
           cat y >>fcst.grib
           $wgrb/wgrib ${filefcst[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[$timelp]} -o y
           cat y >>fcst.grib          

           if [ -s ${filefcst03[$timelp]} ] && [ $tnd03 = 'open' ] ; then
             $wgrb/wgrib ${filefcst03[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst03[$timelp]} -o y
             cat y >>fcst03.grib
             $wgrb/wgrib ${filefcst03[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst03[$timelp]} -o y
             cat y >>fcst03.grib
           fi
           if [ -s ${filefcst06[$timelp]} ] && [ $tnd06 = 'open' ] ; then
             $wgrb/wgrib ${filefcst06[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst06[$timelp]} -o y
             cat y >>fcst06.grib
             $wgrb/wgrib ${filefcst06[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst06[$timelp]} -o y
             cat y >>fcst06.grib
           fi
           if [ -s ${filefcst12[$timelp]} ] && [ $tnd12 = 'open' ] ; then
             $wgrb/wgrib ${filefcst12[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst12[$timelp]} -o y
             cat y >>fcst12.grib
             $wgrb/wgrib ${filefcst12[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst12[$timelp]} -o y
             cat y >>fcst12.grib
           fi
           if [ -s ${filefcst24[$timelp]} ] && [ $tnd24 = 'open' ] ; then
             $wgrb/wgrib ${filefcst24[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst24[$timelp]} -o y
             cat y >>fcst24.grib
             $wgrb/wgrib ${filefcst24[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst24[$timelp]} -o y
             cat y >>fcst24.grib
           fi

           timelp=`expr $timelp + 1`
         done
      fi

    if [ $cloud_base_from_sfc = "no" ] ; then
     varslp=0
     while [ $varslp -lt $nvar ]             # for cloud base/top, need surface height
      do
      if [ ${k5[$varslp]} -eq 7 ] ; then
         if [ ${k6[$varslp]} -eq 2 ] || [ ${k6[$varslp]} -eq 3 ] ; then
           $wgrb/wgrib ${filefcst[0]} |grep "kpds5=7:kpds6=1:kpds7=0"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[0]} -o sfc.grib
           $gribindex sfc.grib sfc.indx
           varslp=$nvar
         fi
       fi
       varslp=`expr $varslp + 1`
     done
    fi

   else                                      # case 2

     varslp=0
     while [ $varslp -lt $nvar ]             # for all variable 
       do
       if [ ${k5[$varslp]} -ne 32 ] ; then   # skip wind vector
         kpds="kpds5="${k5[$varslp]}":kpds6="${k6[$varslp]}
         timelp=0
         while [ $timelp -lt ${tobsv[0]} ] # for all later-on verfied data
           do
            $wgrb/wgrib ${fileobsv[$timelp]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv[$timelp]} -o x
            cat x >>obsv.grib

            if [ $tnd03 = 'open' ] ; then           
             $wgrb/wgrib ${fileobsv03[$timelp]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv03[$timelp]} -o x
             cat x >>obsv03.grib
            fi
            if [ $tnd06 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv06[$timelp]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv06[$timelp]} -o x
             cat x >>obsv06.grib
            fi
            if [ $tnd12 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv12[$timelp]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv12[$timelp]} -o x
             cat x >>obsv12.grib
            fi
            if [ $tnd24 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv24[$timelp]} |grep $kpds|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv24[$timelp]} -o x
             cat x >>obsv24.grib
            fi

            $wgrb/wgrib ${filefcst[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[$timelp]} -o y
            cat y >>fcst.grib

            if [ -s ${filefcst03[$timelp]} ] && [ $tnd03 = 'open' ] ; then
              $wgrb/wgrib ${filefcst03[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst03[$timelp]} -o y
              cat y >>fcst03.grib
            fi
            if [ -s ${filefcst06[$timelp]} ] && [ $tnd06 = 'open' ] ; then
              $wgrb/wgrib ${filefcst06[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst06[$timelp]} -o y
              cat y >>fcst06.grib
            fi
            if [ -s ${filefcst12[$timelp]} ] && [ $tnd12 = 'open' ] ; then
              $wgrb/wgrib ${filefcst12[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst12[$timelp]} -o y
              cat y >>fcst12.grib
            fi
            if [ -s ${filefcst24[$timelp]} ] && [ $tnd24 = 'open' ] ; then
              $wgrb/wgrib ${filefcst24[$timelp]} |grep $kpds|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst24[$timelp]} -o y
              cat y >>fcst24.grib
            fi
            timelp=`expr $timelp + 1`
           done
        fi       
           varslp=`expr $varslp + 1`
      done
  
      nvar_1=`expr $nvar - 1`
      if [ ${k5[$nvar_1]} -eq 32 ] ; then  #if vector wind is specfied, also specifiy U and V (no matter if U,V already spcified
        timelp=0
        while [ $timelp -lt ${tobsv[0]} ] # for all later-on verfied data
        do
           $wgrb/wgrib ${filefcst[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[$timelp]} -o y
           $wgrb/wgrib ${fileobsv[$timelp]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv[$timelp]} -o x
           cat x >>obsv.grib
           cat y >>fcst.grib
           $wgrb/wgrib ${filefcst[$timelp]} |grep "kpds5=34"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[$timelp]} -o y
           $wgrb/wgrib ${fileobsv[$timelp]} |grep "kpds5=34"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv[$timelp]} -o x
           cat x >>obsv.grib
           cat y >>fcst.grib
          
           if [ -s ${filefcst03[$timelp]} ] && [ $tnd03 = 'open' ] ; then
             $wgrb/wgrib ${filefcst03[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst03[$timelp]} -o y
             cat y >>fcst03.grib
             $wgrb/wgrib ${filefcst03[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst03[$timelp]} -o y
             cat y >>fcst03.grib
           fi
           if [ -s ${fileobsv03[$timelp]} ] && [ $tnd03 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv03[$timelp]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv03[$timelp]} -o x
             cat x >>obsv03.grib
             $wgrb/wgrib ${fileobsv03[$timelp]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv03[$timelp]} -o x
             cat x >>obsv03.grib
           fi

           if [ -s ${filefcst06[$timelp]} ] && [ $tnd06 = 'open' ] ; then
             $wgrb/wgrib ${filefcst06[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst06[$timelp]} -o y
             cat y >>fcst06.grib
             $wgrb/wgrib ${filefcst06[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst06[$timelp]} -o y
             cat y >>fcst06.grib
           fi
           if [ -s ${fileobsv06[$timelp]} ] && [ $tnd06 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv06[$timelp]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv06[$timelp]} -o x
             cat x >>obsv06.grib
             $wgrb/wgrib ${fileobsv06[$timelp]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv06[$timelp]} -o x
             cat x >>obsv06.grib
           fi
           if [ -s ${filefcst12[$timelp]} ] && [ $tnd12 = 'open' ] ; then
             $wgrb/wgrib ${filefcst12[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst12[$timelp]} -o y
             cat y >>fcst12.grib
             $wgrb/wgrib ${filefcst12[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst12[$timelp]} -o y
             cat y >>fcst12.grib
           fi
           if [ -s ${fileobsv12[$timelp]} ] && [ $tnd12 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv12[$timelp]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv12[$timelp]} -o x
             cat x >>obsv12.grib
             $wgrb/wgrib ${fileobsv12[$timelp]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv12[$timelp]} -o x
             cat x >>obsv12.grib
           fi
           if [ -s ${filefcst24[$timelp]} ] && [ $tnd24 = 'open' ] ; then
             $wgrb/wgrib ${filefcst24[$timelp]} |grep "kpds5=33:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst24[$timelp]} -o y
             cat y >>fcst24.grib
             $wgrb/wgrib ${filefcst24[$timelp]} |grep "kpds5=34:"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst24[$timelp]} -o y
             cat y >>fcst24.grib
           fi
           if [ -s ${fileobsv24[$timelp]} ] && [ $tnd24 = 'open' ] ; then
             $wgrb/wgrib ${fileobsv24[$timelp]} |grep "kpds5=33:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv24[$timelp]} -o x
             cat x >>obsv24.grib
             $wgrb/wgrib ${fileobsv24[$timelp]} |grep "kpds5=34:"|grep $accumuobsv|$wgrb/wgrib -i -grib ${fileobsv24[$timelp]} -o x
             cat x >>obsv24.grib
           fi
           timelp=`expr $timelp + 1`
        done    
      fi

    if [ $cloud_base_from_sfc = "no" ] ; then
     varslp=0
     while [ $varslp -lt $nvar ]             # for cloud base/top, need surface height
      do
      if [ ${k5[$varslp]} -eq 7 ] ; then
         if [ ${k6[$varslp]} -eq 2 ] || [ ${k6[$varslp]} -eq 3 ] ; then
           $wgrb/wgrib ${filefcst[0]} |grep "kpds5=7:kpds6=1:kpds7=0"|grep $accumufcst|$wgrb/wgrib -i -grib ${filefcst[0]} -o sfc.grib
           $gribindex sfc.grib sfc.indx
           varslp=$nvar
         fi
       fi
       varslp=`expr $varslp + 1`
     done
    fi


  fi

      #ls -l 

      $gribindex fcst.grib fcst.indx
      $gribindex obsv.grib obsv.indx

      if [ $tnd03 = 'open' ] ; then
        $gribindex fcst03.grib fcst03.indx
        $gribindex obsv03.grib obsv03.indx
      fi
      if [ $tnd06 = 'open' ] ; then      
       $gribindex fcst06.grib fcst06.indx
       $gribindex obsv06.grib obsv06.indx
      fi
      if [ $tnd12 = 'open' ] ; then
       $gribindex fcst12.grib fcst12.indx
       $gribindex obsv12.grib obsv12.indx
      fi
      if [ $tnd24 = 'open' ] ; then
       $gribindex fcst24.grib fcst24.indx
       $gribindex obsv24.grib obsv24.indx
      fi

   rm -f x y

 read LINE                      #Header 9
   echo $LINE >> g2g.ctl
   set -A level $LINE
   loop=${level[0]}
   while [ $loop -gt 1 ]
    do
     read LINE
     echo $LINE >> g2g.ctl
     loop=`expr $loop - 1`
   done

  echo $cloud_base_from_sfc >>  g2g.ctl  #Header 10
  echo $lat_weight >> g2g.ctl            #Header 11 


   mv g2g.ctl g2g.ctl.$model
   mv fcst.grib fcst.grib.$model 
   mv fcst.indx fcst.indx.$model
   mv obsv.grib obsv.grib.$model
   mv obsv.indx obsv.indx.$model
 if [ $tnd03 = 'open' ] ; then
   mv fcst03.grib fcst03.grib.$model
   mv fcst03.indx fcst03.indx.$model
   mv obsv03.grib obsv03.grib.$model
   mv obsv03.indx obsv03.indx.$model
 fi
 if [ $tnd06 = 'open' ] ; then
   mv fcst06.grib fcst06.grib.$model
   mv fcst06.indx fcst06.indx.$model
   mv obsv06.grib obsv06.grib.$model
   mv obsv06.indx obsv06.indx.$model
 fi
 if [ $tnd12 = 'open' ] ; then
   mv fcst12.grib fcst12.grib.$model
   mv fcst12.indx fcst12.indx.$model
   mv obsv12.grib obsv12.grib.$model
   mv obsv12.indx obsv12.indx.$model
 fi
 if [ $tnd24 = 'open' ] ; then
   mv fcst24.grib fcst24.grib.$model
   mv fcst24.indx fcst24.indx.$model
   mv obsv24.grib obsv24.grib.$model
   mv obsv24.indx obsv24.indx.$model
 fi



if [ ${tfcst[1]} -gt 2000000000 ] ; then 
 echo $model ${tfcst[1]} > temp
fi
if [ ${tobsv[1]} -gt 2000000000 ] ; then
 echo $model ${tobsv[1]} > temp
fi

exit
 

