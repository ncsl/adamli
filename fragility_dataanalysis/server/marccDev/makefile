SHELL := /usr/bin/env bash

MARCC_USER=ali39@jhu.edu
ssh 							:= ssh $(port)
remote	          := $(MARCC_USER)@gateway2.marcc.jhu.edu

*check-env:
	@[[ ! -z "$$MARCC_USER" ]] || \
	{ echo "Missing id to use on MARCC server, usually your JHED email. Run 'export MARCC_USER=yourusername'" ; exit 1 ; }

*list-adj:
	@{ ls ../../serverdata/adjmats/notchfilter/;\
	  ls ../../serverdata/pertmats/notchfilter/;\
	ls ../../serverdata/adjmats/notchfilter/win250_step125_freq1000/;\
		ls ../../serverdata/pertmats/notchfilter/win250_step125_freq1000_radius${rad}/;\
}

# rsync -aP /path/to/source /path/to/destination
# *sync-local-files:
# 	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/serverdata/ ../../serverdata/;\
# }

######################### Syncing to Cloud #########################
# Sync data up to the cloud
*sync-data:
	@{ rsync -aP /Volumes/ADAM\ LI/data/ ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/data/;\
}

######################### Syncing to Local #########################
# Sync temporary files to local to do testing
*sync-temp-files:
	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/server/marccDev/matlab_lib/tempData/notchfilter/win250_step125/connectivity/LA15_ICTAL/; \
	./matlab_lib/tempData/;\
}

# Sync ltv model files to local
*sync-adj-files:
	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/serverdata/adjmats/notchfilter/ /Volumes/ADAM\ LI/serverdata/adjmats/notchfilter/;\
}

# Sync perturbation model files to local
*sync-pert-files:
	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/serverdata/pertmats/notchfilter/ /Volumes/ADAM\ LI/serverdata/pertmats/notchfilter/;\
}


######################### Functions to Make #########################
ssh: *check-env
	$(ssh) $(remote)
list: *list-adj

sync-to-local-adj: *sync-adj-files
sync-to-local-pert: *sync-pert-files
sync-to-local-temp: *sync-temp-files
sync-to-remote-data: *sync-data