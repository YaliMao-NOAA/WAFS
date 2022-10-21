#!/bin/sh

set -x
echo "current dir=" `pwd`

#############################################
# compare data with baseline data
#############################################

for file in $filelist; do
  if [ -e $COMOUT/$file ] ; then

    # compare to UK blended data if it's available
    comparetypes="base"
    if [[ ! -z $fileUK ]] && [[ $file == WAFS* ]] ; then
	comparetypes="$comparetypes uk"
    fi

    for comparetype in $comparetypes ; do
	if [[ $comparetype == "uk" ]] ; then
	    newtestname="$testname (compared to UK)"
	    diffile=${file}.UK.diff
	    basefile=$fileUK
	else
	    newtestname=$testname
	    diffile=${file}.diff
	    basefile=${file}
	fi
	cmp $COMOUT/$file $basedir/data_out/$PDY/$basefile
	err=$?
	if [ $err -eq 0 ] ; then
	    msg="$newtestname generates bitwise identical file: $file"
	elif [ $err -eq 2 ] ; then
	    msg="$newtestname basedir does not yet have the sample data for: $file"
	else
	    msg="$newtestname does not generate bitwise identical file: $file"
	    echo " start comparing each grib record and write the comparison result to *diff files"
	    echo " check $diffile to make sure the changes are intended"

	    # cmp_grib2_grib2 return value ( 0: different 1: same)
	    #
	    # If B is a subset of A and the first records are the same,
	    # cmp_grib2_grib2 A B => no difference
	    # cmp_grib2_grib2 B A => with error message
	    $cmp_grib2_grib2 $basedir/data_out/$PDY/$basefile $COMOUT/$file > $diffile
	    err1=$?
	    $cmp_grib2_grib2 $COMOUT/$file $basedir/data_out/$PDY/$basefile
	    err2=$?

	    if [[ $err1 -eq $err2 && $err1 -eq 0 ]] || [[ $err1 -ne $err2 ]] ; then
		if [[ $err1 -eq $err2 && $err1 -eq 0 ]] ; then # Two files have differences
		    echo "Two files are different, keep $diffile"
		else # One file is a subset of the other file
		    echo "#### One file is the subset of the other ####" > $diffile
		fi
		# List fields of each file
		# 1. File names
		echo $basedir/data_out/$PDY/$basefile  > diffile.prepend
		echo "vs" >> diffile.prepend
		echo $COMOUT/$file >> diffile.prepend

		# 2. File sizes
		echo "`stat -c %s $basedir/data_out/$PDY/$basefile` bytes    vs   `stat -c %s $COMOUT/$file` bytes" >> diffile.prepend
		echo >> diffile.prepend

		# Prepend #1 #2 to $diffile
		cat diffile.prepend $diffile > tmp.file ; mv tmp.file $diffile
		echo >> $diffile

		# 3. List of fields side by side
		$WGRIB2 $basedir/data_out/$PDY/$basefile | cut -d':' -f1,4- > base.fields
		$WGRIB2 $COMOUT/$file | cut -d':' -f1,4- > this.fields
		paste base.fields this.fields |awk -F'\t' '{printf("%-50s %s\n",$1,$2)}' > comp.fields

		# 4. Min, Max and Max difference in percentile
		$WGRIB2 $basedir/data_out/$PDY/$basefile -min | cut -d"=" -f2 > base.min
		$WGRIB2 $COMOUT/$file -min | cut -d"=" -f2 > this.min
		$WGRIB2 $basedir/data_out/$PDY/$basefile -max | cut -d"=" -f2 > base.max
		$WGRIB2 $COMOUT/$file -max | cut -d"=" -f2 > this.max
		while true ; do
		    read -r compfield <&3 || break
		    read -r min1 <&4 || break
		    read -r min2 <&5 || break
		    read -r max1 <&6 || break
		    read -r max2 <&7 || break
		    # 3. List of fields side by side
		    printf "%s" "$compfield" >> $diffile
		    printf "\n" >> $diffile
		    if (( $( echo "$max1 != 0 && $max2 != 0" | bc -l ) )) ; then
			maxdiff=$(echo $max1 $max2 | awk '{ printf "%.2f", ($2-$1)/$1*100.0 }')
		    else
			maxdiff=""
		    fi
		    # 4. Min, Max and Max difference in percentile
		    printf "  MIN: %-10s vs %-10s  MAX: %-10s vs %-10s  MAX diff: %-7s" $min1 $min2 $max1 $max2 "${maxdiff}%">> $diffile
                    printf "\n" >> $diffile
		done 3<comp.fields 4<base.min 5<this.min 6<base.max 7<this.max

		# 5. The rest of fields if one file has more records than the other
		n1=`cat base.fields | wc -l`
		n2=`cat this.fields | wc -l`
		nsame=$(( n1<n2 ? n1:n2 ))
		ndiff=$(( n1>n2 ? n1:n2 ))
		ndiff=$(( ndiff - nsame ))
		if [ $ndiff -ne 0 ] ; then
		    echo >> $diffile
		    echo "(One file has more records than the other.)" >> $diffile
		    tail -n $ndiff comp.fields >> $diffile
		fi

#		rm comp.fields base* this*
	    fi
	fi
	postmsg "$logfile" "$msg"
	cp $diffile $COMOUT/.
    done

  else
    msg="$testname ERROR: fails generating file $file"
    postmsg "$logfile" "$msg"
  fi
done

echo $?
echo "PROGRAM IS COMPLETE!!!!!!"
msg="Ending $testname test"
postmsg "$logfile" "$msg"
postmsg "$logfile" ""
