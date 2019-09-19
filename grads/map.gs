function map(arg)

*
*/u/Wesley.Ebisuzaki/grads.2.0.2/scripts/map.gs
*
* asks you which map projection to use
* easier than set lat ...
*
* of course this script needs to be customized
* script originally was part of the revised BAMS 
* reanalysis cd-rom demo
*
* usage:  run map [optional map type]
*
* v1.2.2 w. ebisuzaki
* v1.2.3 w. ebisuzaki added alaska
* v1.2.4 w. ebisuzaki tasmania
* v1.2.5 w. ebisuzaki added rr
* v1.2.6 w. ebisuzaki changed mres to newmap except for USA
* v1.2.7 w. ebisuzaki fork for NARR and 2006 DVD
* v1.2.8 w. ebisuzaki added EQ xxN and xxS
* v1.2.9 w. ebisuzaki added usa3 usa4
*
if (arg = '')
   say 'change projection of the display:'
   say '  nps (north-pole stereographic)'
   say '  sps (sorth-pole stereographic)'
   say '  lola  (lat-lon) (0..360)'
   say '  lola2 (lat-lon) (-180..180)'
   say '  usa/usa3, usa2/usa4, ec, wc, alaska, canada, n_amer rr/rr2'
   say '  s_amer, africa, europe, euro2, asia, aust, tasmania'
   say '  robinson c_pac n_pac n_atl nps2 nps3'
   say '  custom [lon0 dlon lat0 dlat] (lat0,lon=left-bottom corner)'
   say ' '
   prompt 'enter projection: '
   pull cmdline
else
   cmdline=arg
endif

map=subwrd(cmdline,1)

proj='latlon'
latr='-90 90'
lonr='0 360'
maptype='lowres'
mpvals='off'

if (map = 'EQ')
  latr='0'
endif
l=math_strlen(map)
c=substr(map,l,1)
if (c = 'N' | c = 'S')
   s=substr(map,1,l-1)
   if (valnum(s) != 0)
      if (c = 'S')
         latr='-'s
      else
         latr=s
      endif
   endif
endif

if (map = 'nps' | map = 'NPS')
  proj='nps'
  latr='20 90'
  lonr='-270 90'
endif
if (map = 'nps2' | map = 'NPS2')
  proj='nps'
  latr='20 90'
  lonr='-180 180'
endif
if (map = 'nps3' | map = 'NPS3')
  proj='nps'
  latr='20 90'
  lonr='-60 300'
endif
if (map = 'sps' | map = 'SPS')
  proj='sps'
  latr='-90 -20'
  lonr='-270 90'
endif
if (map = 'usa' | map = 'USA')
  maptype='mres'
  proj='latlon'
  latr='24 52'
  lonr='-127 -65'
endif
if (map = 'usa3' | map = 'USA3')
  maptype='mres'
  proj='latlon'
  latr='24 52'
  lonr='233 295'
endif


if (map = 'usa4' | map = 'USA4')
  maptype='mres'
  proj='nps'
  latr='15 80'
  lonr='210 315'
  mpvals='-125 -75 25 55'
endif
if (map = 'ec' | map = 'EC')
  maptype='mres'
  proj='latlon'
  latr='24 50'
  lonr='-100 -65'
endif
if (map = 'wc' | map = 'WC')
  maptype='mres'
  proj='latlon'
  latr='24 50'
  lonr='-128 -90'
endif
if (map = 'n_amer' | map = 'N_AMER')
  maptype='mres'
  proj='nps'
  latr='5 90'
  lonr='-270 90'
  mpvals='-135 -65 18 85'
endif
if (map = 'rr' | map = 'RR')
  maptype='mres'
  proj='nps'
  latr='0 90'
  lonr='-250 120'
  mpvals='-155 -60 14 84'
endif
if (map = 'rr2' | map = 'RR2')
  maptype='mres'
  proj='nps'
  latr='0 82'
*  lonr='-200 70'
  lonr='150 440'
  mpvals='-120 -75 14 82'
endif
if (map = 'alaska' | map = 'ALASKA')
  maptype='mres'
  proj='nps'
  latr='50 73'
  lonr='-180 -120'
endif
if (map = 'canada' | map = 'CANADA')
  maptype='mres'
  proj='nps'
  latr='40 80'
  lonr='-145 -50'
endif
if (map = 's_amer' | map = 'S_AMER')
  maptype='newmap'
  proj='latlon'
  latr='-60 20'
  lonr='-90 -30'
endif
if (map = 'africa' | map = 'AFRICA')
  maptype='newmap'
  proj='latlon'
  latr='-40 50'
  lonr='-20 60'
endif
if (map = 'europe' | map = 'EUROPE')
  maptype='newmap'
  proj='nps'
  latr='5 90'
  lonr='-180 180'
  mpvals='-10 50 30 75'
endif
if (map = 'euro2' | map = 'EURO2')
  maptype='newmap'
  proj='nps'
  latr='5 90'
  lonr='-180 180'
  mpvals='-56 36 29 68'
endif
if (map = 'asia' | map = 'ASIA')
  maptype='newmap'
  proj='latlon'
  latr='0 80'
  lonr='40 170'
endif
if (map = 'aust' | map = 'AUST' | map = 'oz')
  maptype='newmap'
  proj='latlon'
  latr='-50 0'
  lonr='100 180'
endif
if (map = 'tas' | map = 'TASMANIA' | map = 'tasmania')
  maptype='newmap'
  proj='latlon'
  latr='-46 -38'
  lonr='143 152'
endif
if (map = 'lola' | map = 'LOLA')
  proj='latlon'
endif
if (map = 'lola2' | map = 'LOLA2')
  proj='latlon'
  lonr='-180 180'
endif
if (map = 'c_pac' | map = 'C_PAC')
  proj='latlon'
  latr='-45 45'
  lonr='120 290'
endif
if (map = 'n_pac' | map = 'N_PAC')
  proj='nps'
  latr='0 90'
  lonr='90 270'
  mpvals='100 260 22 89'
endif
if (map = 'robinson' | map = 'ROBINSON')
  proj='robinson'
  latr='-90 90'
  lonr='-180 180'
endif
if (map = 'custom' | map = 'CUSTOM' )
* custom lon0 dlon lat0 dlat
  maptype='newmap'
  proj='latlon'
  lon0=subwrd(cmdline,2)
  dlon=subwrd(cmdline,3)
  lat0=subwrd(cmdline,4)
  dlat=subwrd(cmdline,5)
  if (dlon <= 0)
     dlon=10
  endif
  if (dlat <= 0)
     dlat=10
  endif

*  for US/Canada . use mres map
  if (lon0 > -180 & lon0 < -40 & lat0 > 0)
    maptype='hires'
  endif
  if (lon0 > 180 & lon0 < 320 & lat0 > 0)
    maptype='hires'
  endif

  lon1=lon0 + dlon
  lat1=lat0 + dlat
  latr=lat0 ' ' lat1
  lonr=lon0 ' ' lon1
endif

'set mpdset ' maptype
'set mpvals ' mpvals

'set mproj ' proj
'set lat ' latr
'set lon ' lonr

