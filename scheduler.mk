# PARAMETERS:
#
# USER_SUPPLIED_DEP_IDS -- specify a job id that all to be scheduled jobs are
# dependent on. Say some job with id 123456 is already running and the file
# output.txt is dependent on its results, then you can type make -f
# Makefile-sbatch 'USER_SUPPLIED_DEP_IDS=123456' output.txt
#
# TODO:
#
# - Namespaces, automated prefixing everything could be an idea. Prevents
#   overwriting variables used in the make file

########################
#       Parameters     #
########################
USER_SUPPLIED_DEP_IDS?=
SCHEDULER?=sbatch
########################
#      /Parameters     #
########################

########################
#  Parameter checking  #
########################
$(if $(filter $(SCHEDULER),sbatch qsub),,$(error Unsupported scheduler. Only qsub and sbatch are supported.))
########################
#  /Parameter checking #
########################

##########################################
#  Variables unchanged after declaration #
##########################################
# For space to comma substitution
COMMA:= ,
EMPTY:=
SPACE:= $(EMPTY) $(EMPTY)

# Check if this is a dry run
DRY_RUN:=$(filter %n n%,$(MAKEFLAGS))

DIRECTORY?=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SBATCH_JOB_SCRIPT?=$(DIRECTORY)/wrapper_jobscript.sbatch
PBS_JOB_SCRIPT?=$(DIRECTORY)/wrapper_jobscript.pbs
##########################################
# /Variables unchanged after declaration #
##########################################

#########################################
#   Variables evaluated when accessed   #
#########################################
# The dependencies of a target that don't exist yet.
NON_EXISTENT_DEPS=$(filter-out $(wildcard $^),$^)

ifeq ($(SCHEDULER),sbatch)
##### SBATCH
# The entire sbatch command that is to be run, $1 are sbatch options, $2 the
# commands to be run
SCHEDULE_CMD=sbatch $(DEP_STRING) $1 $(SBATCH_JOB_SCRIPT) $2
# Create the sbatch like dependency string -d afterok:jobid1,afterok:jobid2
define CREATE_DEP_STRING
$(if $(or $1,$(USER_SUPPLIED_DEP_IDS)),-d $(subst $(SPACE),$(COMMA),$(foreach dep,$1 $(USER_SUPPLIED_DEP_IDS),afterok:$(dep))),)
endef
# Output from the sbatch command, contains job id in last word if successfull. TODO: check errors
define GET_JOB_ID_FROM_SUBMIT_RESULT
$(lastword $1)
endef
##### /SBATCH
else
##### QSUB
# The entire qsub command that is to be run, $1 are qsub options, $2 the
# commands to be run
SCHEDULE_CMD=qsub $(DEP_STRING) $1 -v QSUB_ARGUMENTS='$2' $(PBS_JOB_SCRIPT)
# Create the qsub like dependency string -d afterok:jobid1,afterok:jobid2
define CREATE_DEP_STRING
$(if $(or $1,$(USER_SUPPLIED_DEP_IDS)),-W depend=afterok:$(subst $(SPACE),:,$(foreach dep,$1 $(USER_SUPPLIED_DEP_IDS),$(dep))),)
endef
# Output from the qsub command, contains job id in first word if successfull. TODO: check errors
define GET_JOB_ID_FROM_SUBMIT_RESULT
$1
endef
##### /QSUB
endif
##########################################
#   /Variables evaluated when accessed   #
##########################################

#########################################################
# The actual function that should be called by the user #
#########################################################
# If this is not a dry run, perform the actual scheduling.
ifeq ($(DRY_RUN),)
# Comments in make can't be written within a define so this is for the entire
# next code block. Call with $(call schedule_with_deps_and_store_id,sbatch_options,cmd_to_be_run)
# DEP_IDS: Get jobids of all dependencies from the SBATCH_DEPENDENCIES list where jobs are stored like $dep1--jobid--$jobid1 $dep2--jobid--$jobid2 $depn--jobid--$jobidn
# SBATCH_DEP_STRING: Create the dependencies option syntax needed for sbatch
define schedule_with_deps_and_store_id
$(eval DEP_IDS=$(foreach dep,$^,$(patsubst $(dep)--jobid--%,%,$(filter $(dep)--jobid--%,$(DEPENDENCIES)))))
$(if $(or $(DEP_IDS),$(USER_SUPPLIED_DEP_IDS)),$(eval DEP_STRING=$(call CREATE_DEP_STRING,$(DEP_IDS) $(USER_SUPPLIED_DEP_IDS))),$(eval DEP_STRING=))
@echo $(SCHEDULE_CMD)
$(eval SUBMIT_RESULT=$(shell $(SCHEDULE_CMD) 2>&1))
@echo $(SUBMIT_RESULT)
$(eval DEPENDENCIES=$(DEPENDENCIES) $@--jobid--$(lastword $(SUBMIT_RESULT)))
endef
else
# This is a dry run, echo command
# SBATCH_DEP_STRING: jobids are not known in a jobrun, except the USER_SUPPLIED_DEP_IDS, so use filenames instead for the unknowns
define schedule_with_deps_and_store_id
$(eval DEP_IDS=$(filter $^,$(DEPENDENCIES)))
$(if $(or $(DEP_IDS),$(USER_SUPPLIED_DEP_IDS)),$(eval DEP_STRING=$(call CREATE_DEP_STRING,$(DEP_IDS) $(USER_SUPPLIED_DEP_IDS))),$(eval DEP_STRING=))
$(SCHEDULE_CMD)
$(eval DEPENDENCIES=$(DEPENDENCIES) $@)
endef
endif
#########################################################
#/The actual function that should be called by the user #
#########################################################
