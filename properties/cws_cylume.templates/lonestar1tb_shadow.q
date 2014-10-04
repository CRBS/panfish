#!/bin/sh
#
#$ -V
#$ -A @PANFISH_ACCOUNT@
#$ -wd @PANFISH_JOB_CWD@
#$ -o @PANFISH_JOB_STDOUT_PATH@
#$ -e @PANFISH_JOB_STDERR_PATH@
#$ -N @PANFISH_JOB_NAME@
#$ -q largemem
#$ -l h_rt=@PANFISH_WALLTIME@
#$ -pe 1way 24

/usr/bin/time -p @PANFISH_RUN_JOB_SCRIPT@ @PANFISH_JOB_FILE@