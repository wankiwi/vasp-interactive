#!/bin/bash -l
#SBATCH -N 1
#SBATCH -C cpu
#SBATCH -q debug
#SBATCH -A m2755
#SBATCH -t 00:10:00


export OMP_NUM_THREADS=1

CONDA_ROOT="/global/homes/t/ttian20/.conda/envs/vpi"
export VASP_COMMAND="srun -n 1 -c 4 --cpu-bind=cores vasp_std"
GIT_REPO="ulissigroup/vasp-interactive"
if [ -z "$GIT_REF" ]
then
    GIT_REF="main"
fi
# conda activate vpi
export PATH=${CONDA_ROOT}/bin:$PATH

uid=`uuidgen`
root=$SCRATCH/vpi-runner/$uid
mkdir -p $root && cd $root
jobid=${SLURM_JOB_ID}
echo "Job ID $jobid"
echo "Running tests under $root"
gh repo clone $GIT_REPO
cd vasp-interactive
git checkout $GIT_REF
echo "Check to $GIT_REF"
export PYTHONPATH=`realpath .`
export TEMPDIR=$SCRATCH

for ver in  "vasp/5.4.4-cpu" "vasp/6.3.2-cpu" "vasp-tpc/5.4.4-cpu" "vasp-tpc/6.3.2-cpu"
do
    module load $ver
    echo "Testing VaspInteractive Compatibility on $ver"
    python examples/ex00_vasp_test.py | tee tmp.out
    RES=`sed -n "s/^Test result:\(.*\)$/\1/p" tmp.out`
    echo $ver, $RES >> perlmutter_cpu.txt
    rm tmp.out
    #module unload vasp
done

if [ -z "${GIST_ID}" ]
then
    echo "No gist ID provided, I'll skip the update part"
else
    gh gist edit ${GIST_ID} -a perlmutter_cpu.txt
    echo "Gist file updated!"
fi