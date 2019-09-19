'set display color white'
'c'
*
'set gxout shaded'
*light yellow to dark red
'set rgb 21 255 250 170'
'set rgb 22 255 232 120'
'set rgb 23 255 192  60'
'set rgb 24 255 160   0'
'set rgb 25 255  96   0'
'set rgb 26 255  50   0'
'set rgb 27 225  20   0'
'set rgb 28 192   0   0'
'set rgb 29 165   0   0'
*
*light green to dark green
'set rgb 31 230 255 225'
'set rgb 32 200 255 190'
'set rgb 33 180 250 170'
'set rgb 34 150 245 140'
'set rgb 35 120 245 115'
'set rgb 36  80 240  80'
'set rgb 37  55 210  60'
'set rgb 38  30 180  30'
'set rgb 39  15 160  15'
*set rgb 39   5 150   5
*
*light blue to dark blue
'set rgb 41 225 255 255'
'set rgb 42 180 240 250'
'set rgb 43 150 210 250'
'set rgb 44 120 185 250'
'set rgb 45  80 165 245'
'set rgb 46  60 150 245'
'set rgb 47  40 130 240'
'set rgb 48  30 110 235'
'set rgb 49  20 100 210'
*
*light purple to dark purple
*'set rgb 51 220 220 255'
*'set rgb 52 192 180 255'
*'set rgb 53 160 140 255'
*'set rgb 54 128 112 235'
*'set rgb 55 112  96 220'   
*'set rgb 56  72  60 200'   
*'set rgb 57  60  40 180'
*'set rgb 58  45  30 165'
*'set rgb 59  40   0 160'
*
*light pink to dark rose  
'set rgb 61 255 230 230'
'set rgb 62 255 200 200'
'set rgb 63 248 160 160'
'set rgb 64 230 140 140'
'set rgb 65 230 112 112'
'set rgb 66 230  80  80'   
'set rgb 67 200  60  60'   
'set rgb 68 180  40  40'
'set rgb 69 164  32  32'
*light beige to dark brown   
'set rgb 71 250 240 230'
'set rgb 72 240 220 210'
'set rgb 73 225 190 180'
'set rgb 74 200 160 150'
'set rgb 75 180 140 130'   
'set rgb 76 160 120 110'  
'set rgb 77 140 100  90'
'set rgb 78 120  80  70'
'set rgb 79 100  60  50'
*
* modifications: w. ebisuzaki
* light grey (reserve 81-89)
'set rgb 81 245 245 245'
'set rgb 82 235 235 235'
'set rgb 83 128 128 128'
* black and white
'set rgb 98 0 0 0'
'set rgb 99 255 255 255'
*
* add more colors for icing product: Y Mao
* probability 50-57
'set rgb 50 203 250 255'
'set rgb 51 143 241 208'
'set rgb 52 131 245 44 '
'set rgb 53 188 233 55'
'set rgb 54 255 255 20'
'set rgb 55 255 200 0'
'set rgb 56 245 150 0'
'set rgb 57 234 79  0'
* potential 50-56 58-60
'set rgb 58 255 90 90'
'set rgb 59 255 0  0'
'set rgb 60 200 0  0'
*
'set rbcols 49 48 47 46 45 44 43 42 41 81 21 22 23 24 25 26 27 28 29'
*'set clevs 0.01 0.06 0.11 0.16 0.21 0.26 0.31 0.36 0.41 0.46 0.51 0.56 0.61 0.66 0.71 0.76 0.81 0.86 0.91 0.96'
*'set  ccols 99 49 48 47 46 45 44 43 42 41 81 82 21 22 23 24 25 26 27 28 29'
* for scenarios of icing severity
*'set ccols 99 32 39 49 44 42 62 64 69 29 71'
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
