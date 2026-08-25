---
layout: default
title: "Dr. James Howe · Cryptography Researcher and Engineer"
---

<div class="hero" markdown="0">
  <img src="files/DSCF5469.jpg" alt="James Howe">
  <div>
    <h1>Dr. James Howe</h1>
    <div class="hero-tagline">Cryptography Researcher and Engineer</div>
    <div class="hero-icons">
      <a href="{{ site.baseurl }}/contact/" title="Contact"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m2 7 10 6 10-6"/></svg></a>
      <a href="https://www.linkedin.com/in/jameshowe1729/" title="LinkedIn"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect x="2" y="9" width="4" height="12"/><circle cx="4" cy="4" r="2"/></svg></a>
      <a href="https://scholar.google.co.uk/citations?user=LItUNn4AAAAJ&hl=en" title="Google Scholar"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10 12 4 2 10l10 6 10-6Z"/><path d="M6 12.5V18c0 1.5 3 3 6 3s6-1.5 6-3v-5.5"/></svg></a>
      <a href="https://github.com/jameshoweee" title="GitHub"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 19c-4.3 1.4-4.3-2.5-6-3m12 5v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1.1-.3-3.5 1.3a12.3 12.3 0 0 0-6.2 0C6.5 2.8 5.4 3.1 5.4 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21"/></svg></a>
      <a href="https://letterboxd.com/jhowe/" title="Letterboxd"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="7" cy="12" r="5"/><circle cx="12" cy="12" r="5"/><circle cx="17" cy="12" r="5"/></svg></a>
    </div>
  </div>
</div>

<div class="bio" markdown="1">

## Professional

I'm a cryptographer, with a focus on practical implementations, cryptanalysis, and protocols related to post-quantum cryptography. 
You can find a link to my publications on [Google Scholar](https://scholar.google.co.uk/citations?user=LItUNn4AAAAJ&hl=en).

I currently lead the cryptography team at [SandboxAQ](https://www.sandboxaq.com/), where I manage our cryptographic research and guide the design and enhancement of our cybersecurity products. My work spans post-quantum cryptography, PQC migration and cryptographic modernization, and strengthening compliance and risk management capabilities. In 2025, our team launched [OpenCryptography.com](https://opencryptography.com/), a free public database mapping cryptographic assets, vulnerabilities, and risks across roughly a billion entries from open-source repositories, containers, and operating system distributions, built to help organizations find their cryptographic exposure and prepare for post-quantum migration. That same analysis capability led us to discover and responsibly disclose [CVE-2025-43023](https://cryptographycaffe.sandboxaq.com/posts/hp-crypto-vuln-disclosure/): an insecure 1024-bit DSA signing key HP had used to sign HPLIP (HP's Linux printer driver suite) releases since 2013.

At SandboxAQ we have a lot of great opportunities for [Residencies](https://www.sandboxaq.com/company/residencies), which can be for anyone from postgraduates to postdocs, for 3-12 months. Please feel free to get in [contact](https://jameshowe.eu/contact/) to informally enquire, I would be interested in topics (in PQC or others) ranging from FPGA or microcontroller designs, side-channel analysis and countermeasures, protocol design, crypto-agility, and developing our open-source tools at SandboxAQ. We also have other researchers, such as [Martin Albrecht](https://martinralbrecht.wordpress.com/2023/04/25/sandboxaq-internships/), who have other topics in mind.

I've had the pleasure of supervising Paula Alonso Blanco, Sanjay Deshpande, Kahlil Dozier, Georg Land, Tarun Yadav, as well as many others in a more informal setting.

For 2.5 years, I was employed as a Cryptography Engineer at [PQShield Ltd](https://dblp.org/pid/138/8975.html), a small spin-out company from the University of Oxford. Previously, I was a post-doc at the University of Bristol in the [SCA / Crypto group](https://github.com/sca-research) and at [CSIT](https://www.qub.ac.uk/ecit/CSIT/) where I also did a research fellowship and my PhD. Other previous research positions and education history can be found in my [CV](files/CV.pdf).

</div>

<div class="section" markdown="1">

## Research Interests

The focus of my research is mainly based around (but not limited to) post-quantum cryptography. My research has somewhat been focused on implementations (optimisations for hardware and software designs), physical implementation attacks (side-channel and fault attacks) and countermeasures. Also I have been researching protocols (such as KEMs, signatures, and beyond) and algorithmic optimisations.

</div>

<div class="tags" markdown="0">
  <span>Post-Quantum Cryptography</span>
  <span>PQC Migration &amp; Modernization</span>
  <span>Protocol Design</span>
  <span>FPGA &amp; Embedded Systems</span>
  <span>Software Optimisation</span>
  <span>Side-Channel Analysis</span>
</div>

{% assign talks_page = site.pages | where: "url", "/talks/" | first %}
{% assign papers_page = site.pages | where: "url", "/publications/" | first %}
{% assign latest_project = site.pages | where: "latest", true | first %}
<div class="section" markdown="0">
  <div class="section-label">Recently</div>
  <div class="recent">
    <a class="card" href="{{ talks_page.latest.url }}">
      <div class="kicker">TALK &middot; {{ talks_page.latest.date | upcase }}</div>
      <div class="title">{{ talks_page.latest.title }}</div>
      <div class="meta">{{ talks_page.latest.meta }}</div>
    </a>
    <a class="card" href="{{ papers_page.latest.url }}">
      <div class="kicker">PAPER &middot; {{ papers_page.latest.venue | upcase }}</div>
      <div class="title">{{ papers_page.latest.title }}</div>
      <div class="meta">{{ papers_page.latest.meta }}</div>
    </a>
    <a class="card" href="{{ latest_project.url }}">
      <div class="kicker">PROJECT</div>
      <div class="title">{{ latest_project.title }}</div>
      <div class="meta">{{ latest_project.tagline }}</div>
    </a>
  </div>
</div>
