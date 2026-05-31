# ECG Denoising Using an FPGA-Based FIR Low-Pass Filter

A digital hardware engineering project showcasing a complete pipeline to denoise raw, corrupted Electrocardiogram (ECG) data using a custom **Finite Impulse Response (FIR) Filter** implemented on an FPGA fabric.

## Digital Architecture & DSP Design
The processing core utilizes discrete linear convolution to isolate high-frequency power line interferences and random environmental noise while preserving critical cardiac timing complexes ($P, QRS, T$):

$$y[n] = \sum_{k=0}^{N-1} h[k] \cdot x[n-k]$$

### Submodule Descriptions
1. **FIR Filter Core (`fir_filter.v`):** A parametric N-tap filter utilizing signed 16-bit math, multi-stage multiplier pipelines, and standardized synchronization signaling interfaces.
2. **UART Receiver Subsystem (`uart_rx.v`):** Deserializes serial streams coming from computer diagnostic links into parallel bytes for the filter bus.
3. **UART Transmitter Subsystem (`uart_tx.v`):** Serializes processed, clean heart samples back to monitoring interfaces.
4. **Top-Level Module (`top_module.v`):** Orchestrates global resets, clock constraints, and hooks the UART peripherals directly into the filtering datapath.

## References
- Jayashree S., Shanthapreetha S., and Velan C., "FPGA Implementation of Optimized FIR Filter for ECG Denoising," *JATIT*, 2022.
- Rahul Sharma, Rajesh Mehra, and Chandni, "FPGA based Asynchronous FIR Filter Design for ECG Signal Processing," *IJCA*, 2016.

## Project Authors (Section A1, Group 02)
- **Rejoun Rahi Rad** (2106003)
- **Abrar Fahim** (2106005)
- **Md. Yeasir Alif** (2106011)
- **Al Muktadir Khan** (2106012)

**Course:** Digital Electronics Laboratory (EEE 304), Bangladesh University of Engineering and Technology (BUET).
