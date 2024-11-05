# LiveG OS Bootstrap Toolchain
Bootstrapping toolchain for building LiveG OS installation disk images.

Licensed by the [LiveG Open-Source Licence](LICENCE.md).

For more information on LiveG OS and its various components, visit [the LiveG OS repository](https://github.com/LiveGTech/OS).

## Prerequisites
Before bootstrapping LiveG OS, you'll need to run this command on a Debian host system to install the required tools:

```bash
sudo apt-get install qemu-utils qemu-system-x86 socat grub-common grub-pc-bin grub-efi-amd64-bin xorriso rsync mtools
```

`sudo` commands will be run throughout the bootstrapping process. To ensure continuity, set the `NOPASSWD` option for `sudo` for your user/group by editing the file provided by running `sudo visudo`.

## Ports that must be open
To allow the toolchain to work properly, please keep the following ports open:

* `8000`: used for hosting files on a web server under the `host` directory
* `8001`: used for hosting a TCP server for communicating with QEMU

## Expected time to bootstrap
Bootstrapping LiveG OS will take around 8 minutes with KVM or 37 minutes without KVM, though this will depend on the specifications of the host system:

### With KVM
* It takes 1 minute to download the base system installer (dependent on speed of internet connection)
* It takes 4 minutes to install the base system to a virtual disk drive
* It takes 0 minutes to to boot the disk drive to the firstboot script
* It takes 2 minutes to run the firstboot script to completion (dependent on speed of internet connection)
* It takes 1 minute to build the ISO file

### Without KVM
* It takes 1 minute to download the base system installer (dependent on speed of internet connection)
* It takes 29 minutes to install the base system to a virutal disk drive
* It takes 1 minute to boot the disk drive to the firstboot script
* It takes 5 minutes to run the firstboot script to completion (dependent on speed of internet connection)
* It takes 1 minute to build the ISO file

Many parts of the bootstrapping process are cached in the `cache/` folder, and so once fully-bootstrapped, bootstrapping again will be quicker to perform. When building some platforms, some steps do not apply, and so the bootstrapping time could vary.

To check whether KVM is enabled, install the `cpu-checker` package, then run the `kvm-ok` command.

> **Note:** If you are using WSL 2 on Windows to perform bootstrapping, then you will need to use WSL 2 version 5.4 or higher. Enable Windows Hypervisor, then add `nestedVirtualization=true` under `[wsl2]` in the WSL 2 config file.

## Bootstrapping
Before bootstrapping, ensure that a the copy of the gShell AppImage file you wish to include exists under `cache/gshell.AppImage`.

To bootstrap LiveG OS, run the following:

```bash
./bootstrap.sh
```

When complete, the distributable ISO file will be available at `build/system.iso`.

You can also specify the platform type to target as an argument:

```bash
./bootstrap.sh x86_64 # Modern PCs with typical Intel or AMD chipset
./bootstrap.sh arm64 # Modern PCs with typical ARM64 chipset
./bootstrap.sh rpi # Raspberry Pi 3/4 computers and CM3/4 SoM chips
./bootstrap.sh pinephone # PINE64 PinePhone smartphone
```

## Distributing
Ensure that the information in `boot.sh` is up-to-date (with regards to details such as version information) before bootstrapping and distributing. The final ISO file can then be distributed.

## Pipeline architecture
Here is the process that the bootstrapper follows to create a system image, where `$PLATFORM` is the target platform:

1. Start web server so that Debian setup preseed file can be accessed from inside the VM

2. Download Debian setup image (`cache/$PLATFORM/base.iso`) if haven't already (skipped if platform is `rpi`)

3. Create base install (`cache/$PLATFORM/baseinstall.img`) if haven't already (downloaded instead if platform is `rpi`)

    a. Create blank system disk (`build/$PLATFORM/system.img`) (skipped if platform is `rpi`)

    b. Boot system disk with QEMU and launch setup with preseed file (setup launch performed by `bootkeys.sh`) (skipped if platform is `rpi`)

    c. Wait for setup to finish (setup is performed without user input, and the VM shuts down and QEMU exits when setup is complete) (skipped if platform is `rpi`)

    d. Move gShell AppImage into host storage (`host/$PLATFORM/cache/gshell.AppImage`)

    e. Mount system disk image to `build/$PLATFORM/rootfs` so that root filesystem can be accessed

    f. Create/modify files in root filesystem to customise system image with LiveG branding, in addition to copying `firstboot.sh` into the root filesystem

    g. Unmount root filesystem, writing changes to system disk image

4. Build bootable ISO image from system disk image (skipped if platform is `rpi`)

    a. Mount system disk image to `build/$PLATFORM/rootfs`

    b. Copy GRUB configuration to root filesystem (`build/$PLATFORM/rootfs/boot/grub/grub.cfg`) as well as fstab file and filesystem overlay setup script (`build/$PLATFORM/rootfs/sbin/initoverlay`; run as `init` so is very first process when booting from Linux kernel)

    c. Make ISO file from root filesystem using `grub-mkrescue`

## Useful commands
* `./bootstrap.sh` to start bootstrapping process
* `./bootstrap.sh --env-only` to set environment variables for shell (to execute scripts such as `mount.sh` and `unmount.sh`)
* `./boostrap.sh --no-emulation` to prevent image emulation; images must be flashed to and processed on real hardware and then confirmed in the OS bootstrapper after copying image back
* `./bootstrap.sh --gshell-dist /path/to/gShell/dist` to automatically copy files from gShell's `dist` folder to the `cache` folder
* `rm -rf cache` to clear cache and run through full bootstrapping process
* `./mount.sh` to modify root filesystem of system disk image (root privileges required)
* `./unmount.sh` to unmount root filesystem and save changes to mounted disk image
* `cp build/system.img cache/system.img && ./makeiso.sh` to make an ISO image after manually modifying `build/$PLATFORM/system.img`
* `./reapplyfirstboot.sh` to test the first-boot script after making changes to `firstboot.sh`
