# nix-nas

# Test in vm

```sh
nix build .#nixosConfigurations.nix-nas.config.system.build.vm
QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nix-nas-vm -nographic; reset
```