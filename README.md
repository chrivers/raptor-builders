# Builder containers for Raptor

This repository contains builder containers for
[Raptor](https://github.com/chrivers/raptor).

> [!TIP]
> 📕 For more information, [read the raptor book](https://chrivers.github.io/raptor/)

## Compatibility

The various builders can construct a wide variety of outputs, suitable for use
with both containers (`systemd-nspawn`), virtual machines (e.g. `qemu`), and
physical hardware.

However, not all combinations are possible. For example, a physical machine will
not boot a `qcow2` image for virtual machines, but `qemu` will be able to boot
either `qcow2` or `raw` images.

The table below provides an overview of the possible options.

In the table, "VM" refers to virtual machines (e.g. `qemu`), while "HW" refers
to running on physical machines.

| Builder           | Format  | `systemd-nspawn` | VM (UEFI) | VM (BIOS) | HW (UEFI) | HW (BIOS) |
|:------------------|---------|:-----------------|:----------|:----------|:----------|:----------|
| `deblive`         | `iso`   | ❌               | ✅        | ✅        | ✅        | ✅        |
| `live-disk-image` | `qcow2` | ❌               | ✅        | ❌        | ❌        | ❌        |
| `live-disk-image` | `raw`   | ❌               | ✅        | ❌        | ✅        | ❌        |
| `disk-image`      | `qcow2` | ❌               | ✅        | ❌        | ❌        | ❌        |
| `disk-image`      | `raw`   | ✅               | ✅        | ❌        | ✅        | ❌        |
| `part-image`      | `raw`   | ✅               | ❌        | ❌        | ❌        | ❌        |

Currently, booting in BIOS mode is only supported by the `deblive` builder, but
the `live-disk-image` and `disk-image` builders could possibly be extended to
support this, in the future.

## `deblive`: Debian Liveboot iso generator

> [!IMPORTANT]
> This builder requires an input from the Debian family.
>
> It should work for Debian derivatives (Ubuntu, etc), as long as the
> prerequisite packages are installed.

This builder generates an `iso` file suitable for live booting. All layers are
packed into read-only squashfs files, which are mounted using overlayfs, on
boot.

| Mount name | Type   | Usage                                                                                                                  |
|:-----------|:-------|:-----------------------------------------------------------------------------------------------------------------------|
| `cache`    | Simple | Contains cache of previously built `.squashfs` files, to avoid repeating the rather expensive build process for these. |
| `input`    | Layers | The Raptor build target(s) that will be put on the iso                                                                 |
| `output`   | File   | Points to the resulting output file.                                                                                   |

This builder has an entire 📕 [section in the Raptor Book](https://chrivers.github.io/raptor/walkthrough/debian/)

## `live-disk-image`: Debian Liveboot disk image generator

> [!IMPORTANT]
> This builder requires an input from the Debian family.
>
> It should work for Debian derivatives (Ubuntu, etc), as long as the
> prerequisite packages are installed.

| Mount name | Type   | Usage                                                                                                                  |
|:-----------|:-------|:-----------------------------------------------------------------------------------------------------------------------|
| `cache`    | Simple | Contains cache of previously built `.squashfs` files, to avoid repeating the rather expensive build process for these. |
| `input`    | Layers | The Raptor build target(s) that will be put on the generated image                                                     |
| `output`   | File   | Points to the resulting output file.                                                                                   |

This builder also generates Debian Liveboot image, but instead of generating a
`.iso` file, it generates a disk image, including a partition table, and
separate partitions for `/`, `/boot` and `/boot/efi`.

The result is a disk image that allows a physical or virtual machine to boot
normally, but the resulting

It uses the Discoverable Partitions Specification[^dps] to make the images
compatible with both physical hardware, virtual machines, and `systemd-nspawn`.

## `disk-image`: Disk image generator

| Mount name | Type    | Usage                                                                                                                  |
|:-----------|:--------|:-----------------------------------------------------------------------------------------------------------------------|
| `input`    | Overlay | The Raptor build target that will be put into the generated image                                                      |
| `output`   | File    | Points to the resulting output file.                                                                                   |

This builder generates disk images, including a partition table, and separate
partitions for `/`, `/boot` and `/boot/efi`.

It uses the Discoverable Partitions Specification[^dps] to make the images
compatible with both physical hardware, virtual machines, and `systemd-nspawn`.

## Environment variables

Several settings can be adjusted via environment variables. These can be specified either on the command line:

```sh
sudo raptor run -e OUTPUT_FORMAT=qcow2 ...
```

or in `Raptor.toml`:

```toml
[run.example-target]
target = "example"

# notice the `env.` prefix!
env.OUTPUT_FORMAT = "qcow2"
```

| Environment     | Default | Usage                                                                                                                                  |
|:----------------|:--------|:---------------------------------------------------------------------------------------------------------------------------------------|
| `OUTPUT_FORMAT` | `raw`   | Output format of the image. Common values include `raw` and `qcow2`. See `qemu-img --help` for the complete list                       |
| `EFI_MB`        | `32`    | Size of ESP, the EFI System Partition (`/boot/efi`)                                                                                    |
| `BOOT_MB`       | `512`   | Size of the boot partition (`/boot`)                                                                                                   |
| `FREE_MB`       | `512`   | How much free space to target in the resulting image.                                                                                  |
| `USED_MB`       | none    | Total disk space of all files in the root filesystem.<br>Calculated when building the image, unless specified manually.                |
| `SIZE_MB`       | none    | The size of the resulting image.<br>Calculated as `EFI_MB + BOOT_MB + USED_MB + FREE_MB`, unless specified manually for exact control. |

[^dps]: Discoverable Partitions Specification: https://uapi-group.org/specifications/specs/discoverable_partitions_specification/
