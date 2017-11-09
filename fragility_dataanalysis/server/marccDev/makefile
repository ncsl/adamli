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

# rsync -aP /Volumes/ADAM\ LI/data/laserablation/LA07* ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/data/laserablation/;
######################### Syncing to Cloud #########################
# Sync data up to the cloud
*sync-data:
	@{ rsync -aP /Volumes/ADAM\ LI/data/ ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/data/;\
}

######################### Syncing to Local #########################
# Sync temporary files to local to do testing
*sync-temp-files:
	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/serverdata/pertmats/notchfilter/win250_step125_freq1000_radius1.5/LA16_ICTAL/ ~/Downloads/temp/;\
}

# rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/server/marccDev/matlab_lib/tempData/perturbation/notchfilter/win250_step125_freq1000/pt1sz2/* ~/Downloads/temp/;\


# Sync ltv model files to local
*sync-adj-files:
	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/serverdata/adjmats/notchfilter/win250_step125_freq1000/${patient}/ ~/Downloads/${patient}/;\
}

# Sync perturbation model files to local
*sync-pert-files:
	@{ rsync -aP ali39@jhu.edu@gateway2.marcc.jhu.edu:/home-1/ali39@jhu.edu/work/adamli/fragility_dataanalysis/serverdata/pertmats/notchfilter/win250_step125_freq1000_radius1.5/${patient}/ ~/Downloads/${patient}/;\
}


######################### Functions to Make #########################
ssh: *check-env
	$(ssh) $(remote)
list: *list-adj

sync-adj: *sync-adj-files
sync-pert: *sync-pert-files
sync-to-local-temp: *sync-temp-files
sync-to-remote-data: *sync-data