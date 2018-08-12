---
layout: page
title: Round5
permalink: /round5/
---

Round5 is our current [NIST PQC](http://csrc.nist.gov/groups/ST/post-quantum-crypto/) proposal, a result of a merger between Round2 and 
[Hila5](/hila5) first-round candidates. The official homepage is at 
[round5.org](https://round5.org).


We have recently released two preprints on Round5:

*	[*"Round5: Compact and Fast Post-Quantum Public-Key 
	Encryption"*](https://round5.org/doc/round5paper.pdf)
	by S. Bhattacharya, O. Garcia-Morchon, T. Laarhoven, R. Rietman, 
	M.-J. Saarinen, L. Tolhuizen, and Z. Zhang.
	[IACR ePrint 2018/725](https://eprint.iacr.org/2018/725), Submitted
	for publication, August 2018.

*	[*"Shorter Messages and Faster Post-Quantum Encryption 
	with Round5 on Cortex M"*](https://round5.org/doc/r5m4text.pdf)
	by M.-J. Saarinen, S. Bhattacharya, O. Garcia-Morchon, R. Rietman, 
	L. Tolhuizen, and Z. Zhang.
	[IACR ePrint 2018/723](https://eprint.iacr.org/2018/723), Submitted
	for publication, August 2018.

We plan to compile the official NIST submission tweak around October 2018.

## r5nd\_tiny

Round5 is currently the fastest post-quantum encryption algorithm in all
NIST security classes where it is implemented. It also has the shortest 
public keys and messages of any lattice-based NIST PQC candidate. The 
Isogeny-based proposal SIKE requires 15-35% less bytes for key establishment 
but is hundreds of times slower, making it impractical for many applications.

In addition to being the orignal author of Hila5, and designer of key 
components of Round5, I wrote the fast C implementation 
reported in the paper *"Shorter Messages.."*, above.
It is available at [https://github.com/round5/r5nd_tiny](https://github.com/round5/r5nd_tiny).

Here is a simple engineering and security comparison for key establishment use 
case on Cortex M4. All of the compared algorithms are at NIST Category 3.

* **Xfer:** Total data transferred (public key + ciphertext), in bytes.
* **Time:** KeyGen() + Encaps() +  Decaps() on Cortex-M4 at 24 MHz, seconds. 
* **Code:** Size of implementation in bytes, excluding hash function etc.
* **Failure:** Decryption failure bound.
* **Post-Quantum:** Claimed quantum complexity.
* **Classical:** Claimed classical complexity.

| **Algorithm** | **Xfer** | **Time** | **Code** | **Failure** | **Post-Quantum** | **Classical** |
| ------------- | :------: | :------: | :------: | :------: | :-----: | :------: |
| R5ND\_3KEM    | 1684    | 0.124   | 4464    | 2<sup>-75</sup>	| 2<sup>176</sup> | 2<sup>193</sup>	|
| R5ND\_3PKE    | 1842    | 0.169   | 5232    | 2<sup>-129</sup>	| 2<sup>181</sup> | 2<sup>193</sup>	| 
| Saber         | 2080    | 0.172   | ?        | 2<sup>-136</sup>	| 2<sup>180</sup> | 2<sup>198</sup>	| 
| Kyber-768     | 2240    | 0.210   | 7016    | 2<sup>-142</sup>	| 2<sup>161</sup> | 2<sup>178</sup>	|
| sntrup4591761 | 2265    | 8.718   | 71024   | 0                | -               | 2<sup>248</sup> |
| NTRU-HRSS17   | 2416    | 7.814   | 11956   | 0                | 2<sup>123</sup> | 2<sup>136</sup> |
| NewHope1024-CCA | 4032  | 0.264   | 12912   | 2<sup>-216</sup>	| 2<sup>233</sup> | -	| 
| SIKEp751      | 1160    | 685.9   | 19112   | 0                | 2<sup>124</sup> | 2<sup>186</sup> |


