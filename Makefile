.PHONY: collie
collie:
	mix escript.build

.PHONY: init
init:
	mix deps.get
	mix escript.build
	collie rebar.get

.PHONY: setup
setup:
	asdf install
	make init