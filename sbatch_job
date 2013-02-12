#!/bin/bash
HELPDOC=$( cat <<EOF
Stubfile for sbatch.

Usage:
    sbatch [sbatch options] sbatch_job [sbatch_job options] command_to_run
Options:
    -h      This help documentation.
    -l      Log filename (default: ~/jobs.log).
    -n      Number of threads.
EOF
)
# Halt on error
set -e

LOGFILE="$HOME/jobs.log"

# Parse options
while getopts ":hn:l:m" opt; do
    case $opt in
        h) 
            echo "$HELPDOC"
            exit 0
            ;;
        n)
            export OMP_NUM_THREADS=$OPTARG
            ;;
        l)
            LOGFILE=$OPTARG
            ;;
        m)
            MEMLOG=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "$HELPDOC"
            exit 1
            ;;  
    esac
done
shift $(($OPTIND - 1))

{
    echo "## ##"
    echo "## START JOB $SLURM_JOB_ID - $SLURM_JOB_NAME"
    echo "## `date`"
    echo "## COMMAND: $@"
    if [ -n "${OMP_NUM_THREADS+1}" ]
    then
        echo "## OMP_NUM_THREADS: $OMP_NUM_THREADS"
    fi
    echo "## LOGFILE: $LOGFILE"
} | tee -a $LOGFILE

T="$(date +%s)"
if [ "$MEMLOG" == true ]
then
    eval valgrind --tool=massif --massif-out-file=massif.out.${SLURM_JOB_NAME}.${SLURM_JOB_ID} $@
else 
    eval $@ 2>&1
fi
T="$(($(date +%s)-T))"

{
    echo "## `date`"
    printf "## Elapsed time: %02d-%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))"
    echo "## FINISHED JOB $SLURM_JOB_ID - $SLURM_JOB_NAME"
    echo "## ##"
} | tee -a $LOGFILE
