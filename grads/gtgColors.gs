'set display color white'
'c'
*
'set gxout shaded'
'set rgb 21 255 255 255'
'set rgb 22 255 255 255'
'set rgb 23 255 255 255'
'set rgb 24 244 255 255'
'set rgb 25 224 255 255'
'set rgb 26 204 255 255'
'set rgb 27 204 255 204'
'set rgb 28 204 255 153'
'set rgb 29 204 255 102'
'set rgb 30 204 255 51'
'set rgb 31 204 255 0'
'set rgb 32 214 244 0'
'set rgb 33 224 234 0'
'set rgb 34 234 224 0'
'set rgb 35 244 214 0'
'set rgb 36 255 204 0'
'set rgb 37 255 193 0'
'set rgb 38 255 183 0'
'set rgb 39 255 173 0'
'set rgb 40 255 163 0'
'set rgb 41 255 153 0'
'set rgb 42 255 142 0'
'set rgb 43 255 132 0'
'set rgb 44 255 122 0'
'set rgb 45 255 112 0'
'set rgb 46 255 102 0'
'set rgb 47 255 81 0'
'set rgb 48 255 61 0'
'set rgb 49 255 40 0'
'set rgb 50 255 20 0'
'set rgb 51 255 0  0'
'set rgb 52 244 0 0'
'set rgb 53 234 0 0'
'set rgb 54 224 0 0'
'set rgb 55 214 0 0'
'set rgb 56 204 0 0'
'set rgb 57 193 0 0'
'set rgb 58 183 0 0'
'set rgb 59 173 0 0'
'set rgb 60 163 0 0'
'set rgb 61 153 0 0'
'set rgb 62 142 0 0'
'set rgb 63 132 0 0'
'set rgb 64 122 0 0'
'set rgb 65 112 0 0'
'set rgb 66 102 0 0'
'set rgb 67 91 0 0'
'set rgb 68 81 0 0'
'set rgb 69 71 0 0'
'set rgb 70 61 0 0'

'set rbcols 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70'
'set clevs  0 .02 .05 .07 .1 .12 .14 .16 .18 .2 .22 .24 .26 .28 .3 .32 .34 .36 .38 .4 .42 .44 .46 .48 .5 .52 .54 .56 .58 .6 .62 .64 .66 .68 .7 .72 .74 .76 .78 .8 .82 .84 .86 .88 .9 .92 .94 .96 .98 1.0'

*
*set mpt type off | <<col><style><thick>>
*         *	-- all types
*         1	-- political boundaries
*         2	-- state and country outlines
'set mpt * 83 1 1'
*
*set mpdset <lowres|mres|hires|nmap>
*            lowres	-- the default. 
*            mres|hires -- state and country outlines. 
*            nmap 	-- only North America.
'set mpdset mres'
*
*Sets color and thickness of axis border, axis labels, and tickmarks
'set annot 98 3'
