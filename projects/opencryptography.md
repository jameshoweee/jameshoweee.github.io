---
layout: project
title: OpenCryptography
tagline: A free public database mapping cryptographic assets, vulnerabilities, and risks across the internet
permalink: /projects/opencryptography/
links:
  - label: OpenCryptography.com
    url: https://opencryptography.com/
  - label: "CVE-2025-43023 Disclosure"
    url: https://cryptographycaffe.sandboxaq.com/posts/hp-crypto-vuln-disclosure/
nav: false
---

In 2025, our team at SandboxAQ launched OpenCryptography.com, a free public database mapping cryptographic assets, vulnerabilities, and risks across roughly a billion entries from open-source repositories, containers, and operating system distributions — built to help organizations find their cryptographic exposure and prepare for post-quantum migration.

That same analysis capability led us to discover and responsibly disclose CVE-2025-43023: an insecure 1024-bit DSA signing key HP had used to sign HPLIP (HP's Linux printer driver suite) releases since 2013.
