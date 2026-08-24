---
layout: project
title: GLITCH
tagline: A Discrete Gaussian Testing Suite for Lattice-Based Cryptography
permalink: /projects/glitch/
github: https://github.com/jameshoweee/glitch
paper: https://eprint.iacr.org/2017/438
paper_venue: SECRYPT 2017
nav: false
---

An earlier statistical testing suite for discrete Gaussian samplers used in lattice-based cryptography, joint work with Máire O'Neill.

The code runs on data files provided in a `samples` directory, covering different sample sizes, different samplers, and deliberately "buggy" samples for validating the tests themselves. The main parameters that can be adapted are the target standard deviation and precision, plus the expected moments (mean, standard deviation, skewness, kurtosis) the sampler should be tested against.

**Note:** an improved and updated version of this code is available as [SAGA](/projects/saga/).
