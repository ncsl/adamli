SHELL := /usr/bin/env bash

ssh 							:= ssh $(port)
remote	          := $(MARCC_USER)@gateway2.marcc.jhu.edu

*check-env:
	@[[ ! -z "$$MARCC_USER" ]] || \
	{ echo "Missing id to use on MARCC server, usually your JHED email. Run 'export MARCC_USER=yourusername'" ; exit 1 ; }

ssh: *check-env
	$(ssh) $(remote)
