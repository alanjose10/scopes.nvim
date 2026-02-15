MINIMAL_INIT = tests/minimal_init.lua

test:
	nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = '$(MINIMAL_INIT)'}"
