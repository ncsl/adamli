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

ssh: *check-env
	$(ssh) $(remote)

list: *list-adj