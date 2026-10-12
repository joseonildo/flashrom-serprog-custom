# flashrom-serprog-custom

A minimal, unofficial customization of **[flashrom](https://github.com/flashrom/flashrom) v1.6.0**, tailored for convenient use with **[pico-serprog](https://github.com/opensensor/pico-serprog)** on a Raspberry Pi Pico (RP2040).

This project keeps flashrom's existing SPI read, erase, write, and verification logic unchanged. Its goal is a cleaner command-line experience, not a new flash programmer or a faster write algorithm.

> **Unofficial derivative.** This repository is not maintained or endorsed by the flashrom project or the pico-serprog developers.

## Changes from upstream

Only two small source-code changes were made against the flashrom **v1.6.0** release:

| File | Change | Effect |
| --- | --- | --- |
| `cli_classic.c` | Initialize `struct cli_options options` with `.show_progress = true` rather than `{ 0 }`. | Enable existing `--progress` output by default. |
| `cli_common.c` | Remove `(chip->tested.wp == NT)` from the condition that triggers the chip support status banner. | Suppress the long `UNTESTED` warning when write protection (WP) is the *only* untested operation. |

The second change **does not mark WP as tested** or change the underlying chip support data. Warnings for other untested operations and failed/known-bad operations remain available.

The default progress display uses flashrom's existing implementation; it is not an added transfer-speed meter.

## Tested setup

| Component | Configuration |
| --- | --- |
| Host | Ubuntu under WSL2 (Linux 6.18.33.2-microsoft-standard-WSL2, x86_64) |
| Base version | flashrom v1.6.0 |
| Programmer | Raspberry Pi Pico (RP2040), pico-serprog firmware |
| Interface | `serprog:dev=/dev/ttyACM0,spispeed=20M` |
| Tested SPI NOR | Macronix MX25L3233F / MX25L3273E, 4 MiB (flashrom chip entry) |
| Build | Meson + Ninja, GCC 15.2.0, `serprog` programmer enabled |

**Observed results:** chip detection, 4 MiB read, full-chip erase, write, and final flashrom `VERIFIED` result succeeded in the tested setup. Progress indicators were displayed automatically for read, erase, and write.

These are results from one hardware setup, not a guarantee for other chips, wiring, clock rates, or programmers. Secure jumper connections are important: an earlier failed verification was traced to poor jumper contact.

## Build from source

Start with the original upstream [flashrom v1.6.0](https://github.com/flashrom/flashrom/releases/tag/v1.6.0), run the provided [reproducible build script](scripts/build-from-upstream.sh) (which checks out upstream v1.6.0 and applies both edits), or apply the two edits manually and then build:

```bash
sudo apt update
sudo apt install -y git build-essential meson ninja-build pkg-config

meson setup build-custom \
    -Dprogrammer=serprog \
    -Dtests=disabled \
    --buildtype=release

meson compile -C build-custom
./build-custom/flashrom --version
```

The `-Dtests=disabled` setting excludes the optional test build; it was useful with GCC 15.2.0 because the bundled cmocka dependency produced a `-Werror=clobbered` compilation failure. Additional dependencies may be needed depending on distribution and build options.

**Important:** `-Dprogrammer=serprog` produces a serprog-focused binary. Other programmer backends, such as CH341A, are **not enabled** in that build.

### Install alongside the distribution version

On the tested Ubuntu environment, the package-provided flashrom is at `/usr/sbin/flashrom`. The custom version was installed separately:

```bash
sudo install -m 755 build-custom/flashrom /usr/local/bin/flashrom
command -v flashrom
sudo sh -c 'command -v flashrom'
```

Confirm that the command resolution selects `/usr/local/bin/flashrom` before relying on `sudo flashrom`. The packaged `/usr/sbin/flashrom` remains available separately.

## Usage

Read the 4 MiB Macronix chip **without explicitly passing** `--progress`:

```bash
sudo flashrom -p serprog:dev=/dev/ttyACM0,spispeed=20M \
  -c "MX25L3233F/MX25L3273E" -r backup.bin
```

Write an image (flashrom retains its original read/compare/update behavior and verification):

```bash
sudo flashrom -p serprog:dev=/dev/ttyACM0,spispeed=20M \
  -c "MX25L3233F/MX25L3273E" -w image.bin
```

Erase the **entire selected chip** (destructive):

```bash
sudo flashrom -p serprog:dev=/dev/ttyACM0,spispeed=20M \
  -c "MX25L3233F/MX25L3273E" -E
```

**Safety:** back up your chip before writing or erasing, check image and chip compatibility, and ensure stable electrical connections and correct 3.3 V logic. Progress reaching 100% is not equivalent to a successful final verification; look for `VERIFIED` after writing. This customization does **not** bypass the initial read performed by flashrom's normal intelligent write algorithm.

## Original projects and acknowledgements

- **[flashrom — original upstream project](https://github.com/flashrom/flashrom)**: the flash programming software, chip database, SPI algorithms, CLI, and existing progress feature were developed by the flashrom project and its many contributors. **All upstream credit belongs to those contributors.**
- **[pico-serprog — opensensor](https://github.com/opensensor/pico-serprog)**: the Raspberry Pi Pico firmware providing the serprog interface used in testing. This firmware is a separate project and is not included here.
- **[José Onildo Sousa](https://github.com/joseonildo)**: integration, testing, and maintenance of this small customization.

Thank you to all developers and maintainers who make these open-source tools possible.

## Licensing and redistribution

flashrom is free software. **Retain the upstream copyright notices, license files, and applicable source-code licensing terms** when distributing modified source or binaries. Refer to the license and copyright files shipped with the original [flashrom v1.6.0 source](https://github.com/flashrom/flashrom). The pico-serprog project has its own licensing and attribution requirements.

This README documents the modification; it does not replace the upstream license text. When publishing the source snapshot, include its original license and attribution files.

## Repository status

The validated WSL build was based on flashrom v1.6.0, with the two changes described above. The [build script](scripts/build-from-upstream.sh) preserves the exact two source-level changes and rebuild instructions. The previously validated WSL executable is **not yet uploaded**; to back it up as well, it must be copied from the user's local WSL environment. The upstream flashrom source and its licenses are obtained from the original project by the script.
