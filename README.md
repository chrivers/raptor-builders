# Builder containers for Raptor

This repository contains builder containers for
[Raptor](https://github.com/chrivers/raptor).

> [!TIP]
> 📕 For more information, [read the raptor book](https://chrivers.github.io/raptor/)

## Compatibility

The various builders can construct a wide variety of outputs, suitable for use
with both containers (`systemd-nspawn`), virtual machines (e.g. `qemu`), and
physical hardware.

Not all combinations are possible. For example, a physical machine will
not boot a `qcow2` image for virtual machines, but `qemu` will be able to boot
either `qcow2` or `raw` images. The table below provides an overview of the
possible options.

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
| `docker-image`    | `tar`   | ❌               | ❌        | ❌        | ❌        | ❌        |

Currently, booting in BIOS mode is only supported by the `deblive` builder, but
the `live-disk-image` and `disk-image` builders could possibly be extended to
support this, in the future.

## Documentation

📕 The [raptor book](https://chrivers.github.io/raptor/builders/overview/)
documents each build container in detail
