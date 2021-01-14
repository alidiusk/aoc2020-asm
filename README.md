# Advent of Code 2020 in x86-64 Assembly

These are solutions to the Advent of Code 2020 challenges in x86-64 assembly. Note that the executables will only work on Linux as they use Linux-specific system calls. If you want to run this on Windows, you can use WSL or a virtual machine to get a Linux system environment.

Each day contains a `Makefile` to build the code, and produces a single executable called `soln`.

## Building
The following tools are required to build the solutions:
* `nasm`
* `gcc`
* `make`

## Running
After you have built the code, you can run it with
```bash
$ ./day01/soln
```

Licensed under GPLv3.
