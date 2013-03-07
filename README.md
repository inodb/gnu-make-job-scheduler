# gnu-make-job-scheduler

## A library for GNU make to schedule rules as jobs with qsub or sbatch

### Introduction

GNU make is not only a popular building tool for compiling programs, but is
also often used to create simple pipelines especially in bioinformatics. On a
computing cluster of nodes, one often has the ability to schedule jobs using a
[job scheduler]. When it comes to running the pipeline one can either:

1. Schedule the entire pipeline in one job
2. Schedule parts of the pipeline in separate jobs. A job that is dependent on
the output of another job should wait for the other job to finish before
starting.

The first option is straightforward to do, but a problem could be that
different parts of the pipeline require different resource usage. For instance
one part could need a node for a day and requires 80GB of RAM then the next part could
best be split up over a 1000 cores running for one hour each. How are you going
to schedule your entire pipeline? A 1000 core job with a memory minimum of
80GB? A single node job of 80GB and wait for 1000 / (nr of cores per node)
hours? In both cases you are spilling valuable resources of the computing
cluster and our precious planet.

I love our planet and do not take lightly to wasting resources on anything
other than things that will get us to more euphoric moments. This library was
developed to help you do the social thing and implement scheduling strategy
number two. It currently supports Torque's qsub and SLURM's sbatch.

### How do I use it?

The strategy works like this. Create one Makefile that has all the rules to
create the files i.e. your pipeline. Then create another Makefile in the same
directory with another name e.g. Makefile-scheduler that has the same targets
and dependencies and includes scheduler.mk. Each rule then calls
`schedule_with_deps_and_store_id` with the resource requirements specified and
the command that is to be executed, which is just `make $@`. See the test/
directory for an example with both sbatch and qsub.

### Why is it so awesome?

This workflow is nice because your scheduling commands are separate from the
rules to make the actual files. To create the files using a job scheduler you
would use `make -f Makefile-scheduler all` and if you don't want to use a
scheduler you just use `make all` (the default is make -f Makefile). Seeing
only the scheduler commands is also possible by supplying the `-n` parameter to
make: `make -nf Makefile-sbatch`. If you output the stdout of the job to
`$@-scheduler.out` or something similar dependend on the target name, you can
also easily see the output that was generated for each target file. 

### How does it work exactly?

There is a wrapper script for each scheduler that simply executes its given
arguments. By calling `schedule_with_deps_and_store_id` this script is
scheduled with given options and arguments to run (should be `make $@`). It
also stores the resulting job id that the scheduling command returns along with
the target filename in a (key,value) like fashion. When the next job is
scheduled it checks if any of its dependencies have a job id in this list and
if so the job is scheduled as to be dependent on that job id (the -d parameter
for sbatch or -W depend for qsub). For further info take a look at scheduler.mk
or ask me.

### Why is my job scheduler not supported?

It is very easy to implement this for other job schedulers. I can do it for
you if you show me how to set up your scheduler or give me access to a cluster
that uses your preferred scheduler.

## KNOWN BUGS
- The variable names in scheduler.mk are quite common so they should actually
  be prefixed by something to make sure it doesn't overwrite other variables.

[job scheduler]: http://en.wikipedia.org/wiki/Job_scheduler

