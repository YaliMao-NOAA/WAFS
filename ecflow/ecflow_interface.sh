if [[ $(hostname) =~ ^[d][login|dxfer] ]]  ; then
    export ECF_HOST="ddecflow01"
elif [[ $(hostname) =~ ^[c][login|dxfer] ]]  ; then
    export ECF_HOST="cdecflow01"
fi
module load ecflow
ecflow_ui &
