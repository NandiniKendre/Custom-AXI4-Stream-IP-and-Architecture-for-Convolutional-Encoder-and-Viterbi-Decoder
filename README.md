# Custom AXI4-Stream IP and Architecture for Convolutional Encoder and Viterbi Decoder

## Overview

This project presents a custom AXI4-Stream IP core implementing a complete forward error correction (FEC) chain consisting of a Convolutional Encoder and Viterbi Decoder. The design is optimized for FPGA-based communication systems requiring high-throughput streaming data processing and reliable error correction.

## Key Features

* Custom AXI4-Stream Interface
* Convolutional Encoder Architecture
* Viterbi Decoder Architecture
* Real-Time Streaming Data Processing
* Modular RTL Design
* FPGA Prototyping and Validation
* Communication-System-Oriented Design

## Architecture

Input Data Stream
→ AXI4-Stream Interface
→ Convolutional Encoder
→ Encoded Bitstream
→ Viterbi Decoder
→ Decoded Data Stream

## Design Components

* AXI4-Stream Slave Interface
* Convolutional Encoder
* Branch Metric Unit (BMU)
* Add-Compare-Select (ACS) Unit
* Survivor Memory Unit
* Traceback Unit
* AXI4-Stream Master Interface

## Applications

* Digital Communication Systems
* Wireless Communication
* Software Defined Radio (SDR)
* FPGA-Based Signal Processing
* Error Control Coding Systems

## Future Work

* ASIC Migration
* Multi-Rate Coding Support
* Higher Constraint Length Architectures
* Integration with OFDM-Based Systems
