SRC          := shared/link-mounts.sh
FEATURES_DIR := .devcontainer/features

# Features that ship link-mounts.sh, discovered from the install.sh that installs it.
DESTS := $(patsubst %/install.sh,%/link-mounts.sh,\
           $(shell grep -l link-mounts.sh $(FEATURES_DIR)/*/install.sh))

.PHONY: all clean
all: $(DESTS)

$(FEATURES_DIR)/%/link-mounts.sh: $(SRC)
	install -m 0644 $< $@

clean:
	rm -f $(DESTS)
