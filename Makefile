# make without argument will perform a iso & install
all: iso install torrent

# Check configuration only without build
check: 
	nix --extra-experimental-features "nix-command flakes" flake check --no-build

# Check configuration only with build
build:
	nix --extra-experimental-features "nix-command flakes" build -L .#nixosConfigurations.glf-installer.config.system.build.toplevel

# Build new iso
iso:
	nix --extra-experimental-features "nix-command flakes" build -L .#iso

build-vm:
	nixos-rebuild build-vm -I nixos-config=./nix-cfg/configuration.nix && ./result/bin/run-glfos-vm 

# Update flake.lock
update:
	nix --extra-experimental-features "nix-command flakes" flake update

# Clean local build
clean:
	@if [ -L "result" ]; then rm result; fi
	nix-collect-garbage
	@if [ -d "iso" ]; then rm -r iso; fi

# Copy image and compute sha256sum
SRC_DIR = result/iso
DEST_DIR = iso
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
install:
	@SRC_IMG=$$(ls -t $(SRC_DIR) | tail -1); \
	DST_IMG="$${SRC_IMG/-x86_64-linux.iso/_$(GIT_BRANCH).iso}"; \
	if [ -n "$$SRC_IMG" ]; then \
		echo "Copying $(SRC_DIR)/$$SRC_IMG to $(DEST_DIR)/$$DST_IMG ..."; \
		install -d $(DEST_DIR); \
		install -m 644 "$(SRC_DIR)/$$SRC_IMG" $(DEST_DIR)/$$DST_IMG && \
		cd $(DEST_DIR) && \
		sha256sum "$$DST_IMG" > "$$DST_IMG.sha256sum"; \
		cat "$$DST_IMG.sha256sum"; \
	fi

# Generate .torrent file for the ISO and include the sha256sum file
torrent:
	@DST_IMG=$$(ls $(DEST_DIR) | grep -E "\.iso$$"); \
	if [ -n "$$DST_IMG" ]; then \
		echo "Generating torrent for $(DEST_DIR)/$$DST_IMG and its checksum file..."; \
		if [ -f "$(DEST_DIR)/$$DST_IMG.torrent" ]; then rm "$(DEST_DIR)/$$DST_IMG.torrent"; fi; \
		cd $(DEST_DIR) && \
		nix-shell -p mktorrent --run "mktorrent -a udp://tracker.opentrackr.org:1337/announce -l 23 -o $${DST_IMG}.torrent $${DST_IMG} $${DST_IMG}.sha256sum"; \
		echo "Torrent generated: $(DEST_DIR)/$${DST_IMG}.torrent"; \
	else \
		echo "No ISO found in $(DEST_DIR)."; \
	fi

.PHONY: all check build iso update clean install torrent
