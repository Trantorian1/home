all:

vm:
	nix build .#qemu && \
	sudo nix run .#patch ./result/iso/qemu.iso ./secrets/keys/qemu.txt && \
	rm drive.img && \
	nix run .#vm ./patched-qemu.iso
