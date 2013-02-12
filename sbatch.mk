# PARAMETERS:
#
# USER_SUPPLIED_DEP_IDS -- specify a job id that all to be scheduled jobs are
# dependent on. Say some job with id 123456 is already running and the file
# output.txt is dependent on its results, then you can type make -f
# Makefile-sbatch 'USER_SUPPLIED_DEP_IDS=123456' output.txt
#
# TODO:
#
# - This bug is pretty important. Unlike standard GNU make that also checks
#   whether a dependency is newer than the target, the
#   schedule_with_deps_and_store_id only schedules a job with the proper
#   dependency if the dependency file doesn't exist yet. If it is being
#   recreated the dependency won't be scheduled and that way the old file or
#   some partial new output might be used.

# For space to comma substitution
COMMA:= ,
EMPTY:=
SPACE:= $(EMPTY) $(EMPTY)

# Check if this is a dry run
DRY_RUN=$(filter %n n%,$(MAKEFLAGS))

# Get directory of the wrapper job script for sbatch
DIRECTORY:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SBATCH_JOB_SCRIPT:=$(DIRECTORY)/sbatch_job

# If this is not a dry run, perform the actual scheduling.
ifeq ($(DRY_RUN),)
# Comments in make can't be written within a define so this is for the entire
# next code block. Call with $(call schedule_with_deps_and_store_id,sbatch_options,cmd_to_be_run)
# NON_EXISTENT_DEPS: Determine all dependencies that don't exist yet.
# deps: Get jobids of all dependencies from the SBATCH_DEPENDENCIES list where jobs are stored like $dep1--jobid--$jobid1 $dep2--jobid--$jobid2 $depn--jobid--$jobidn
# SBATCH_DEP_STRING: Create the dependencies option syntax needed for sbatch -d afterok:jobid1,afterok:jobidn if there are any dependencies
# SBATCH_CMD: the entire sbatch command that is to be run
# SBATCH_SUBMIT: output from the sbatch command, contains job id in last word if successfull. TODO: Error checking?
define schedule_with_deps_and_store_id
$(eval NON_EXISTENT_DEPS=$(filter-out $(wildcard $^),$^))
$(eval deps=$(foreach dep,$(NON_EXISTENT_DEPS),$(patsubst $(dep)--jobid--,,$(filter $(dep)--jobid--%,$(SBATCH_DEPENDENCIES)))))
$(if $(or $(deps),$(USER_SUPPLIED_DEP_IDS)),$(eval SBATCH_DEP_STRING=-d $(subst $(SPACE),$(COMMA),$(foreach dep,$(deps) $(USER_SUPPLIED_DEP_IDS),afterok:$(dep)))),$(eval SBATCH_DEP_STRING=))
$(eval SBATCH_CMD=sbatch $(SBATCH_DEP_STRING) $1 $(SBATCH_JOB_SCRIPT) $2)
@echo $(SBATCH_CMD)
$(eval SBATCH_SUBMIT=$(shell $(SBATCH_CMD)))
@echo $(SBATCH_SUBMIT)
$(eval SBATCH_DEPENDENCIES=$(SBATCH_DEPENDENCIES) $@--jobid--$(lastword $(SBATCH_SUBMIT)))
endef
else
# This is a dry run, only echo command
# SBATCH_DEP_STRING: jobids are not known in a jobrun, except the USER_SUPPLIED_DEP_IDS, so use filenames instead for the unknowns
define schedule_with_deps_and_store_id
$(eval NON_EXISTENT_DEPS=$(filter-out $(wildcard $^),$^))
$(if $(or $(NON_EXISTENT_DEPS),$(USER_SUPPLIED_DEP_IDS)),$(eval SBATCH_DEP_STRING=-d $(subst $(SPACE),$(COMMA),$(foreach dep,$(NON_EXISTENT_DEPS) $(USER_SUPPLIED_DEP_IDS),afterok:$(dep)))),$(eval SBATCH_DEP_STRING=))
$(eval SBATCH_CMD=sbatch $(SBATCH_DEP_STRING) $1 $(SBATCH_JOB_SCRIPT) $2)
@echo $(SBATCH_CMD)
endef
endif
