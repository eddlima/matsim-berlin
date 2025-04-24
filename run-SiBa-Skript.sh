#!/bin/bash --login
#SBATCH --time=200:00:00
#SBATCH --output=logfile_%x-%j.log
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --mail-user=eduardo.lima@outlook.de
#SBATCH --job-name=SiBa-Shuttle-1min-1pct

date
hostname

jar="./app.jar"
memory="${RUN_MEMORY:-60G}"
config="${RUN_CONFIG:-./input/v6.4/berlin-v6.4-SiBa.config.xml}"

arguments="--1pct"

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
