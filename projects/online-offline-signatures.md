---
layout: project
title: Online/Offline Signatures
tagline: A proof-of-concept implementation of post-quantum online/offline signatures
permalink: /projects/online-offline-signatures/
github: https://github.com/jameshoweee/online-offline-sigs
paper: https://eprint.iacr.org/2025/117.pdf
paper_venue: CT-RSA 2025
nav: false
---

A proof-of-concept, non-optimised implementation made for the "Post-Quantum Online/Offline Signatures" paper, joint work with Martin R. Albrecht, Nicolas Gama, and Anand Kumar Narayanan. It splits Falcon signing into a slow offline step and a fast online step, with cross-platform benchmarks on Apple Silicon, x86-64, and the ARM Cortex-M7 — the online step is consistently the cheapest signing operation across all three platforms.
