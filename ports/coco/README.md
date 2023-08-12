# TurbOS (CoCo Port)

## Building

To build a bootable disk image named `turbos.dsk`, type: `make clean dsk`.

## Running

Mount the disk image on a real CoCo or an emulator, then in Disk BASIC, type: `RUN "*"`.

The 32x16 VDG screen remains intact, with the system stack appearing in the middle of the screen.

The `go` program is a simple test program that increments the first two characters of the screen at alternating intervals.

See [go.asm](go.asm) for more information.