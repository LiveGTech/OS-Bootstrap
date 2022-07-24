# LiveG OS Bootstrap Toolchain
Bootstrapping toolchain for building LiveG OS installation disk images.

Licensed by the [LiveG Open-Source Licence](LICENCE.md).

## Prerequisites
Before bootstrapping LiveG OS, you'll need to run this command on Debian to install the required tools:

```bash
$ sudo apt-get install qemu
```

## Ports that must be open
To allow the toolchain to work properly, please keep the following ports open:

* `8000`: used for hosting files on a web server under the `host` directory
* `8001`: used for hosting a TCP server for communicating with QEMU

## Bootstrapping
To bootstrap LiveG OS, run the following:

```bash
$ ./bootstrap.sh
```