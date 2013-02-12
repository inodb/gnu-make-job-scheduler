gnu-make-sbatch-tools
=========
sbatch job scheduling with GNU make
-----
Schedules jobs using sbatch with dependencies. If you use GNU make as a
pipeline tool to create files that require a lot of resources to compute and
you use sbatch to schedule jobs, this job dependency solver might be for you.

My strategy works like this. Create one Makefile that has all the rules to
create the files, then create another Makefile in the same directory with
another name e.g. Makefile-sbatch that has the same targets and dependencies
and includes sbatch.mk. Each rule then calls `schedule_with_deps_and_store_id`
with the resource requirements and the command that is to be executed, which
is just `make $@`. The `-d` parameter of sbatch is determined with the
`schedule_with_deps_and_store_id function`. This workflow is nice because your
sbatch commands are separate from the rules to make the actual files. To
create the files using sbatch you would use `make -f Makefile-sbatch all` and
if you don't want to use sbatch you just use `make all`. Seeing only the sbatch
commands is also possible by supplying the `-n` parameter to make like `make -nf
Makefile-sbatch`. I guess it would be fairly straightforward to make this work
for other clusters as well but I have no experience with other scheduling
programs. Example will follow.

### KNOWN BUGS
Unlike standard GNU make that also checks whether a dependency is newer than
the target, the `schedule_with_deps_and_store_id` from sbatch.mk only schedules a
job with the proper dependency if the dependency file doesn't exist yet. If it
is being recreated the dependency won't be scheduled and that way the old file
or some partial new output might be used.
