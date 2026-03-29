MINIMAL_INIT = tests/minimal_init.lua

# Find plenary.nvim in CI (/tmp/nvim-plugins) or local lazy install
PLENARY := $(firstword $(wildcard /tmp/nvim-plugins/plenary.nvim $(HOME)/.local/share/nvim/lazy/plenary.nvim))
PLENARY_RTP := $(if $(PLENARY),--cmd "set rtp+=$(PLENARY)",)

test:
	nvim --headless $(PLENARY_RTP) -c "PlenaryBustedDirectory tests/ {minimal_init = '$(MINIMAL_INIT)'}"
