# Builder containers for Raptor

This repository contains builder containers for
[Raptor](https://github.com/chrivers/raptor).

> [!TIP]
> 📕 For more information, [read the raptor book](https://chrivers.github.io/raptor/)

## `deblive`: Debian Liveboot iso generator

| Mount name          | Type   | Usage                                                                                                                  |
|:--------------------|:-------|:-----------------------------------------------------------------------------------------------------------------------|
| `cache` (aka `-C`)  | Simple | Contains cache of previously built `.squashfs` files, to avoid repeating the rather expensive build process for these. |
| `input` (aka `-I`)  | Layers | The Raptor build target(s) that will be put on the iso                                                                 |
| `output` (aka `-O`) | File   | Points to the resulting output file.                                                                                   |

This builder has an entire 📕 [section in the Raptor Book](https://chrivers.github.io/raptor/walkthrough/debian/)

## `disk-image`: Debian Liveboot disk image generator

| Mount name          | Type    | Usage                                                                                                                  |
|:--------------------|:--------|:-----------------------------------------------------------------------------------------------------------------------|
| `cache` (aka `-C`)  | Simple  | Contains cache of previously built `.squashfs` files, to avoid repeating the rather expensive build process for these. |
| `input` (aka `-I`)  | Overlay | The Raptor build target that will be put into the generated image                                                      |
| `output` (aka `-O`) | File    | Points to the resulting output file.                                                                                   |

This builder also generates Debian Liveboot image, but instead of generating a
`.iso` file, it generates a raw disk image, including a partition table, and
separate partitions for `/`, `/boot` and `/boot/efi`.
