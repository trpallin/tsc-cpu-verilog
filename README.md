# Computer Architecture Lab Implementations

This repository contains the Verilog implementations for three different components studied in the Computer Architecture course: Pipelined CPU, Cached CPU, and Direct Memory Access (DMA). Each implementation is organized into its own directory with detailed descriptions of the design, implementation, and performance analysis.

## Table of Contents
- [Pipelined CPU](#pipelined-cpu)
- [Cached CPU](#cached-cpu)
- [Direct Memory Access (DMA)](#direct-memory-access-dma)

## Pipelined CPU

### Introduction
This implementation demonstrates a pipelined CPU designed to enhance the utilization of CPU resources by processing multiple instructions simultaneously across different stages. The project includes handling data and control hazards using techniques like data forwarding and branch prediction.

### Design
The pipelined CPU is divided into five stages:
- **IF (Instruction Fetch)**
- **ID (Instruction Decode)**
- **EX (Execute)**
- **MEM (Memory Access)**
- **WB (Write Back)**

Key components include:
- **Latching Registers:** To hold intermediate data and control signals between stages.
- **Branch Target Buffer (BTB):** For branch prediction.
- **Forwarding Unit:** To handle data hazards through data forwarding.

### Implementation
- **Baseline:** A basic pipelined CPU without any hazard mitigation.
- **Data Forwarding:** Reduces data hazards by forwarding data from later stages to earlier stages when needed.
- **Branch Prediction:** Implements both always-taken strategy and 2-bit predictors to mitigate control hazards.

### Performance
Different strategies were compared, showing significant improvements in IPC (Instructions Per Cycle) with data forwarding and branch prediction techniques.

#### Performance Table
| Strategy | Performance |
| --- | --- |
| Baseline (ID stage branch resolution, always taken) | 2002 cycle |
| Baseline (MEM stage branch resolution, always taken) | 2248 cycle |
| Data-forwarding, always-taken | 1452 cycle |
| Data-forwarding, 2-bit saturation counter | 1473 cycle |
| Data-forwarding, 2-bit hysteresis counter | 1461 cycle |

Figure 1. Performance of pipelined CPU

## Cached CPU

### Introduction
This project explores the impact of cache memory on CPU performance. A direct-mapped cache with write-through and write-no-allocate policies was implemented to enhance memory access speeds.

### Design
- **Baseline:** Implements a simple pipelined CPU with a fixed memory access latency.
- **Cache:** Separate instruction and data caches (I-cache and D-cache) are used, with address bits partitioned into tag, index, block offset, and granularity bits. The cache interacts with the CPU and memory, improving access times on cache hits.

### Implementation
- **Memory Module:** Modified to include latency counters to simulate memory access delays.
- **Cache Module:** Manages cache hits and misses, updating the CPU and memory accordingly. Implements write policies to handle different scenarios.

### Performance
The introduction of cache significantly improved CPU performance, reducing the number of cycles required to execute instructions and increasing the IPC.

#### Performance Table
| Strategy | Performance | IPC |
| --- | --- | --- |
| Baseline | 3453 | 0.2844 |
| Write-through/write-no-allocate direct-mapped cache | 2840 | 0.3458 |

Figure 2. Performance comparison

#### Cache Hit Rate
| Cache | Hit Rate |
| --- | --- |
| I-Cache | 0.9167 |
| D-Cache | 0.9750 |

Figure 3. Cache hit rate

## Direct Memory Access (DMA)

### Introduction
This project focuses on the implementation of Direct Memory Access (DMA) to understand how external devices can interact with memory and CPU without continuous CPU intervention.

### Design
- **Baseline DMA:** A simple DMA controller that handles fixed-address writes.
- **Cycle Stealing DMA:** Enhances the baseline by allowing the CPU to temporarily regain control of the memory bus during DMA operations, reducing the CPU's idle time.

### Implementation
- **Baseline:** DMA controller requests and releases the memory bus based on interrupt signals and handles fixed-size data transfers.
- **Cycle Stealing:** The controller periodically releases the bus to the CPU, which can then execute non-memory instructions, thereby improving overall system performance.

### Performance
Comparative analysis shows that cycle stealing DMA reduces the CPU stall times due to cache misses, leading to better overall performance.

#### Performance Comparison
| Strategy | Clock | Finish Time |
| --- | --- | --- |
| Baseline | 2849 | 285050 ns |
| Extra | 2843 | 284450 ns |

Figure 4. Performance comparison between baseline and extra at FIRE_TIME 19000ns
