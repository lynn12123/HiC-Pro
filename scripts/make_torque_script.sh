#!/bin/bash
## Eric Viara updated 2014-05-05
##

dir=$(dirname $0)

. $dir/hic.inc.sh

usage()
{
    echo "usage: $0 -c CONFIG TORQUE_SUFFIX"
}

while [ $# -gt 0 ]
do
    case "$1" in
	(-c) ncrna_conf=$2; shift;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*)  suffix=$1; break;;
    esac
    shift
done

if [ -z "$suffix" -o -z "$ncrna_conf" ]; then usage; exit 1; fi

read_config $ncrna_conf

unset FASTQFILE

fastqfile=fastqfile_${suffix}.txt

get_hic_files $RAW_DIR .fastq | sed -e "s|$RAW_DIR||" -e "s|^/||" > $fastqfile

count=$(cat $fastqfile | wc -l)

torque_script=HiC_torque_${suffix}.sh
#PPN=8
#PPN=12
PPN=4
cat > ${torque_script} <<EOF
#!/bin/bash
#PBS -l nodes=1:ppn=${PPN},mem=10gb,walltime=6:00:00
#PBS -M $(id -u -n)@curie.fr
#PBS -m ae
#PBS -j eo
#PBS -N HiC_${suffix}
#PBS -q batch
#PBS -V
#PBS -t 1-$count

cd \$PBS_O_WORKDIR

FASTQFILE=\$PBS_O_WORKDIR/$fastqfile; export FASTQFILE
make CONFIG_FILE=${ncrna_conf} all_qsub
EOF

chmod +x ${torque_script}

echo "The following command will launch $count torque jobs:"
echo qsub ${torque_script}