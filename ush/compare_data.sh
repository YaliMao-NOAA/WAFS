#!/bin/sh

set -x

#############################################
# compare data with baseline data
#############################################

cd $COMOUT

for file in $filelist; do
  if [ -e $file ] ; then

    # compare to UK data if it's available
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
	    basefile=${file}.$machine
	fi
	cmp $COMOUT/$file $basedir/data_out/$basefile
	err=$?
	if [ $err -eq 0 ] ; then
	    msg="$newtestname generates bitwise identical file: $file"
	    echo $msg
	elif [ $err -eq 2 ] ; then
	    msg="$newtestname basedir does not yet have the sample data for: $file"
	    echo $msg
	else
	    msg="$newtestname does not generate bitwise identical file: $file"
	    echo $msg
	    echo " start comparing each grib record and write the comparison result to *diff files"
	    echo " check $diffile to make sure the changes are intended"

	    # cmp_grib2_grib2 return value ( 0: different 1: same)
	    #
	    # If B is a subset of A and the first records are the same,
	    # cmp_grib2_grib2 A B => no difference
	    # cmp_grib2_grib2 B A => with error message
	    $cmp_grib2_grib2 $basedir/data_out/$basefile $file > $diffile
	    err1=$?
	    $cmp_grib2_grib2 $file $basedir/data_out/$basefile
	    err2=$?

	    if [[ $err1 -eq $err2 && $err1 -eq 0 ]] || [[ $err1 -ne $err2 ]] ; then
		if [[ $err1 -eq $err2 && $err1 -eq 0 ]] ; then # Two files have different fields
		    echo >> $diffile
		else # One file is a subset of the other file
		    echo "#### One file is the subset of the other ####" > $diffile
		fi
		# List fields of each file
		echo $basedir/data_out/$basefile $file  >> $diffile
		echo "`stat -c %s $basedir/data_out/$basefile` bytes    vs   `stat -c %s $file` bytes" >> $diffile
		$WGRIB2 $basedir/data_out/$basefile | cut -d':' -f1,4- > base.fields
		$WGRIB2 $file | cut -d':' -f1,4- > this.fields
		pr -w 100 -m -t base.fields this.fields > comp.fields
		cat comp.fields >> $diffile
		rm *fields
	    fi
	fi
	postmsg "$logfile" "$msg"
    done

  else
    msg="ERROR: $testname fails generating file: $file"
    echo $msg
    postmsg "$logfile" "$msg"
  fi
done

echo $?
echo "PROGRAM IS COMPLETE!!!!!!"
msg="Ending $testname test"
postmsg "$logfile" "$msg"
