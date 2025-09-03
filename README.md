rz-tracetest
============

This is a testing tool for the correctness of RzIL lifters, which compares
executions of instructions from a real trace against the result of executing
the same instructions in the RzIL VM.

The idea is very similar to
[bap-veri](https://github.com/BinaryAnalysisPlatform/bap-veri) and it uses the
same trace format, called
[bap-frames](https://github.com/BinaryAnalysisPlatform/bap-frames).

Trace sources
-------------

The following sources are currently known to produce meaningful results with
rz-tracetest:

* [QEMU](https://github.com/BinaryAnalysisPlatform/qemu) Patched for the BAP
  project. Specifically useful for ARM and potentially later x86 too.
* [VICE](https://github.com/rizinorg/vice) Patched VICE emulator for testing
  6502.
* [SameBoy](https://github.com/rizinorg/SameBoy) Patched Game Boy emulator for
  testing gb (sm83)

Other sources which have not been tested with rz-tracetest specifically yet:

* [bap-pintraces](https://github.com/BinaryAnalysisPlatform/bap-pintraces) using
  Intel Pin. Useful for x86, but alas Pin is proprietary.

Building
--------

First, install rizin and make sure the bap-frames submodule is up to date:
```
git submodule update --init
```

Afterwards install the build dependencies:
```
sudo apt install libprotobuf-dev protobuf-compiler
```

Then:
```
cd rz-tracetest
# -DCMAKE_BUILD_TYPE=Debug for debugging, -DENABLE_ASAN=1 for ASAN
cmake -Bbuild -GNinja
ninja -C build
```

This will build the `rz-tracetest` executable in `build/`.

Usage
-----

After obtaining a trace, run `rz-tracetest` on it. It will execute all
contained instructions and print mismatches between the trace and RzIL if found:
```
rz-tracetest mytrace.frames
```

Adjustments to specific Archs/Sources/...
-----------------------------------------

In many cases, data given in the trace does not directly map to Rizin. For
example, the arch plugin name must be determined and register names might
differ.
These adjustments, which are in general specific to a certain architecture or
trace source, are performed by implementing the `TraceAdapter` interface. See
`VICETraceAdapter` for an example.

Trace format
------------

The trace consists of three parts: the header,
a table of contents (TOC) holding the frame entries, and an index into the TOC.

Each frame entry starts with the size of the frame, followed by the actual frame data.
A fixed number of frame entries are considered one _entry_ in the TOC.

The TOC index is stored at the end.

[!IMPORTANT]
The last TOC entry might holds less than `m` frames.

For specifics about the frame contents, please check the definitions in the [piqi](piqi/) directory.

**Format**

| Offset | Type | Field | Trace section |
|--------|------|-------|------|
|    0x0    | uint64_t | magic number (7456879624156307493LL) | Header begin |
|    0x8    | uint64_t | trace version number | |
|    0x10    | uint64_t | frame_architecture | |
|    0x18    | uint64_t | frame_machine, 0 for unspecified. | |
|    0x20    | uint64_t | n = total number of frames in trace. | |
|    0x28    | uint64_t | T = offset to TOC index. | |
|    0x30    | uint64_t | sizeof(frame_0) | TOC begin  |
|    0x38    | meta_frame   | frame_0 | |
|    0x40    | uint64_t     | sizeof(frame_1) | |
|    0x48    | type(frame_1) | frame_1 | |
|    ...     | ...          | ... | |
|    T-0x10  | uint64_t     | sizeof(frame_n-1) | |
|    T-0x8   | type(frame_n-1) | frame_n-1 | |
|    T+0     | uint64_t     | m = number of frames per TOC entry | TOC index begin |
|    T+0x8   | uint64_t     | offset toc_entry(0) | |
|    T+0x10  | uint64_t     | offset toc_entry(1) | |
|    ...     | ...          | ... | |
|    T+0x8+(0x8*ceil(n/m))   | uint64_t     | offset toc_entry(ceil(n/m)) | |

Works with TCG tracing plugin
-----------------------------

| Architecture | Works with TCG plugin |
|--------------|-----------------------|
| Hexagon      | Yes                   |
| PPC          | No - register and endian mismatches |
| ARM          | No - Cannot trace cpu modes |
