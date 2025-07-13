#!/bin/bash --login
#SBATCH --time=200:00:00
#SBATCH --output=logfile_%x-%j.log
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --mail-user="e.de.almeida.lima@campus.tu-berlin.de"
#SBATCH --job-name=SiBa_v2-10min-10pct

date
hostname

jar="../../app.jar"
memory="${RUN_MEMORY:-60G}"
config="${RUN_CONFIG:-../v6.4/berlin-v6.4-SiBa_v2.config.xml}"

arguments="--10pct --config:controller.outputDirectory ../../output-SiBa_v2-10pct"

# Don't change anything below
################

jvm_opts="-Xmx$memory -Xms$memory -XX:+AlwaysPreTouch -XX:+UseParallelGC"
command="java $jvm_opts $JAVA_OPTS -cp $jar org.matsim.run.RunOpenBerlinScenario --config $config $RUN_ARGS $arguments run"

echo ""
echo "command is $command"

echo ""
module add java/21
java -version

$command
