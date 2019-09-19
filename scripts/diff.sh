# ksh /global/save/Yali.Mao/save/scripts/diff.sh dir1 dir2

dir1=$1
dir2=$2

files1=`ls $dir1`
files2=`ls $dir2`

yesfiles=""

nofiles=""
for afile in $files1 ; do
  exist=`ls $dir2/$afile 2>/dev/null`
  if [[ -z $exist  ]] ; then
    nofiles="$afile $nofiles"
  else
    yesfiles="$afile $yesfiles"
  fi
done
if [[ ! -z $nofiles && $nofiles != "" ]] ; then
   echo "Under $dir2, no such files:"
   echo $nofiles
fi

echo "====================================================="

nofiles=""
for afile in $files2 ; do
  exist=`ls $dir1/$afile 2>/dev/null`
  if [[ -z $exist  ]] ; then
    nofiles="$afile $nofiles"
  fi
done
if [[ ! -z $nofiles && $nofiles != "" ]] ; then
   echo "Under $dir1, no such files:"
   echo $nofiles
fi

echo "====================================================="

for afile in $yesfiles ; do
  echo  diff $dir1/$afile $dir2/$afile
  diff $dir1/$afile $dir2/$afile
  echo
done