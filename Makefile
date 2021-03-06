# Makefile for bootstrapping virtual machines and ISO images
# file: Makefile

# Makefile configuration -------------------------------------------------------
# - settings
.ONESHELL:      # no sub shells, because of running commands in python venv
SHELL          := bash
SHELLFLAGS     := -eu -o pipefail -c
MAKEFLAGS      += --warn-undefined-variables
MAKEFLAGS      += --no-builtin-rules
# - general purpose vars for constructing parameters
comma          := ,
empty          :=
space          := $(empty) $(empty)
# end of Makefile configuration ------------------------------------------------

.ONESHELL:
# - dynamic targets and command vars
commit-msg     := .git/hooks/commit-msg
git-branch      = $(shell git branch --show-current 2>/dev/null | printf 'main')
pre-commit     := .git/hooks/pre-commit

venv           := .env
activate       := source $(venv)/bin/activate
check          := $(venv)/bin/pre-commit
cz             := $(venv)/bin/cz
pip            := $(venv)/bin/pip
python         := $(venv)/bin/python
release        := $(venv)/bin/semantic-release

export GH_TOKEN:= $(shell keyring get jam82 gh_token)
# init targets #################################################################

.git:
	git init

$(venv): .git
	python -m venv $(venv)

.PHONY: pip
pip: $(venv) venv
	$(pip) install --upgrade pip

.PHONY: setup
setup: pip venv
	$(pip) install -r requirements.txt --upgrade

$(pre-commit): setup venv
	pre-commit install

$(commit-msg): $(pre-commit) venv
	pre-commit install --hook-type commit-msg

.PHONY: init
init: $(commit-msg)

.PHONY: venv
venv: FORCE
	test $${VIRTUAL_ENV} || $(activate)

# end of init targets ##########################################################

.PHONY: add
add:
	@git add .

.PHONY:
changelog:
	@$(release) changelog

.PHONY: check
check: add
	@$(check) run

.PHONY: clean
clean:
	@rm -rf .env

.PHONY: commit
commit: add
	@git commit || true

.PHONY: push
push: commit
	@git push

.PHONY: pull
pull:
	@git pull

.PHONY: release
release: changelog push
	@$(release) publish

FORCE: ;
