
  <div align="center">

<pre>
 ██████╗ ███████╗██╗███╗   ██╗████████╗
██╔═══██╗██╔════╝██║████╗  ██║╚══██╔══╝
██║   ██║███████╗██║██╔██╗ ██║   ██║
██║   ██║╚════██║██║██║╚██╗██║   ██║
╚██████╔╝███████║██║██║ ╚████║   ██║
 ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝
</pre>

### PASSIVE RECONNAISSANCE TOOLKIT

**Set your target. Run your workflow. Document your findings.**

</div>
</pre>

# OSINT-RECON

### Passive Reconnaissance Toolkit for Security Assessments

**Set your target. Run your workflow. Document your findings.**

A shell-based OSINT toolkit that brings common reconnaissance tasks into one repeatable workflow. Collect public intelligence, investigate potential attack-surface exposures, and keep your notes and evidence organised throughout authorised security engagements.

<br/>

![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Kali%20Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![Focus](https://img.shields.io/badge/Focus-OSINT%20%26%20Recon-7B61FF?style=for-the-badge)
![Purpose](https://img.shields.io/badge/Purpose-Authorised%20Assessments-D97706?style=for-the-badge)

</div>

---

## ◈ Overview

Reconnaissance often involves switching between tools, repeating commands, opening research websites, and manually recording observations.

**OSINT-RECON simplifies that process.**

Configure your target once, run individual reconnaissance functions or execute the main workflow, and collect results in a structured directory. Add investigation notes as you go and track screenshots using timestamps and SHA-256 hashes.

> **Authorisation required:** This toolkit is intended for security assessments conducted with appropriate permission and a clearly defined scope. Publicly accessible information and passive techniques can still be subject to legal, contractual, and privacy requirements.

## ◈ Features

| Capability | Description |
|:--|:--|
| **Domain Intelligence** | WHOIS, DNS records, SPF, DMARC, DKIM, and TXT-record service hints |
| **Subdomain Enumeration** | Discover subdomains through certificate transparency, passive DNS, and web archives |
| **DNS Resolution** | Resolve discovered hosts and identify CNAME configurations that warrant further investigation |
| **Email Discovery** | Search for publicly indexed email addresses using theHarvester |
| **Document Metadata** | Extract metadata from locally saved public documents using ExifTool |
| **OSINT Research** | Open research sources and targeted search queries in manageable batches |
| **Evidence Tracking** | Record notes and maintain a screenshot log with timestamps and SHA-256 hashes |
| **Active Web Fingerprinting** | Optionally fingerprint live web hosts after explicit confirmation |

## ◈ Workflow

<div align="center">

`CONFIGURE` → `COLLECT` → `ENUMERATE` → `INVESTIGATE` → `DOCUMENT`

</div>

| Phase | Activity |
|:--|:--|
| `01 / CONFIGURE` | Set the target domain and optional organisation name |
| `02 / COLLECT` | Gather domain registration, DNS, and email-authentication information |
| `03 / ENUMERATE` | Discover subdomains, resolve hosts, and flag interesting DNS configurations |
| `04 / INVESTIGATE` | Explore research sources, inspect document metadata, and validate potential leads |
| `05 / DOCUMENT` | Record observations, preserve evidence, and prepare verified findings for reporting |

## ◈ Requirements

Designed for Kali Linux and Debian-based environments.

Install the required packages:

```bash
sudo apt update

sudo apt install -y \
  subfinder \
  amass \
  theharvester \
  httpx-toolkit \
  libimage-exiftool-perl \
  flameshot \
  jq \
  curl \
  dnsutils \
  whois
```

Ensure the installed package versions and command names match those expected by `osint.sh`.

## ◈ Installation

### 1. Place the script in your local bin directory

From the directory containing `osint.sh`:

```bash
mkdir -p ~/bin
cp osint.sh ~/bin/osint.sh
chmod +x ~/bin/osint.sh
```

### 2. Create a shell alias

The alias loads the functions into your current shell.

**Zsh:**

```bash
echo 'alias recon="source ~/bin/osint.sh"' >> ~/.zshrc
source ~/.zshrc
```

**Bash:**

```bash
echo 'alias recon="source ~/bin/osint.sh"' >> ~/.bashrc
source ~/.bashrc
```

Open a new terminal or reload your shell configuration if necessary.

## ◈ Quick Start

Set the target and, optionally, the organisation name.

```bash
export TARGET="https://www.example.com"
export COMPANY="Example Corp Ltd"

recon
```

`TARGET` can be a full URL if the script supports normalising it to a domain. `COMPANY` is optional and is used for organisation-related searches.

Once loaded, the reconnaissance functions are available in your current shell.

### Command Reference

| Command | Description |
|:--|:--|
| `o_whois` | Retrieve WHOIS information |
| `o_dns` | Inspect DNS records, SPF, DMARC, DKIM, and TXT-record service hints |
| `o_subs` | Run passive subdomain enumeration |
| `o_resolve` | Resolve subdomains and flag potential CNAME takeover candidates |
| `o_emails` | Discover email addresses through theHarvester |
| `o_all` | Run `o_whois`, `o_dns`, `o_subs`, `o_resolve`, and `o_emails` in sequence |
| `o_sites` | Open research sources in batches of five |
| `o_meta` | Extract metadata from locally saved documents |
| `o_web` | **Active:** fingerprint live web hosts after confirmation |
| `o_summary` | Summarise collected counts and investigation notes |
| `n "message"` | Add a note to the investigation |
| `shot name "description"` | Capture and log a screenshot |

### Example: Recording an Observation

Add a note:

```bash
n "Public staging subdomain discovered; verify ownership and exposure."
```

Capture supporting evidence:

```bash
shot staging_host "Public staging host observed during reconnaissance"
```

The `shot` function opens a screen-area selector, saves the screenshot, and records it with a timestamp and SHA-256 hash.

Use neutral, factual notes. Treat observations as leads until they have been independently verified.

## ◈ Research Sources

The `o_sites` function opens a collection of research sources in batches, helping reduce the need to open each site manually.

Sources may include:

| Source | Research purpose |
|:--|:--|
| [crt.sh](https://crt.sh/) | Certificate transparency searches |
| [Shodan](https://www.shodan.io/) | Internet-exposed service research |
| [Censys](https://search.censys.io/) | Internet asset and certificate research |
| [VirusTotal](https://www.virustotal.com/) | Domain and indicator intelligence |
| [GitHub](https://github.com/search) | Public code and repository searches |
| [Google Search](https://www.google.com/) | Targeted searches for publicly indexed information |

Availability and search results depend on each service. Some sites require authentication, and access may be subject to service-specific terms and limits.

## ◈ Evidence & Output

All results are written under:

```text
~/recon/<domain>/
```

Expected directory structure:

```text
<domain>/
├── evidence/
│   ├── raw/
│   │   └── Tool output and collected data
│   └── screenshots/
│       └── Investigation screenshots
└── notes/
    ├── notes.md
    ├── evidence_log.csv
    ├── subdomains.txt
    ├── interesting_subdomains.txt
    ├── resolved.txt
    ├── cnames.txt
    └── emails.txt
```

The precise files generated depend on the functions executed and the script's implementation.

### Evidence handling

- **Raw output:** Retain collected results for subsequent review.
- **Investigation notes:** Record observations and potential findings as the assessment progresses.
- **Screenshot log:** Track screenshots using timestamps and SHA-256 hashes.
- **Finding validation:** Verify potential vulnerabilities before reporting them.

A SHA-256 hash can help detect whether a file has changed since its hash was recorded. It does not independently prove when the file was created or establish a complete chain of custody.

## ◈ Active Checks

### `o_web` — Live Web Fingerprinting

Unlike passive collection, `o_web` sends HTTP requests to live web hosts.

Before running it:

- Confirm that the target is explicitly included in the engagement scope.
- Verify that the rules of engagement permit the checks.
- Confirm the authorised testing window.
- Respect rate limits and any restrictions specified by the client.

The confirmation prompt is an additional safeguard, not a substitute for authorisation.

## ◈ Known Limitations

### DNS resolution

`o_dns` relies on the local resolver. If the resolver is unavailable or misconfigured, records may be missing or misleading, particularly in virtual-machine NAT environments.

Cross-check important records against an independent resolver when necessary:

```bash
dig @8.8.8.8 +short TXT _dmarc.example.com
```

Replace `example.com` with the authorised target domain. Using an external resolver sends the query to that resolver.

### Email discovery

TheHarvester can return stale, unrelated, or unexpected results, including results associated with its own test data.

Validate discovered addresses and their relevance to the target before reporting them.

### CNAME takeover candidates

A suspicious CNAME does not prove that a subdomain is vulnerable to takeover.

Confirm the DNS configuration, service state, and provider-specific conditions before classifying a finding.

### Third-party research services

Some sources, including GitHub code search and LinkedIn, may require authentication. Search coverage, access restrictions, and results can change over time.

### Tool compatibility

Package versions, command names, external service changes, and API availability can affect results. Verify tool compatibility if a function fails unexpectedly.

## ◈ Reporting Recommendations

Reconnaissance results are not automatically confirmed vulnerabilities.

Validate each potential finding and document:

| Report field | What to include |
|:--|:--|
| **Finding** | Clear title and concise description |
| **Severity** | Risk rating supported by the evidence |
| **Affected asset** | Host, domain, endpoint, or other in-scope asset |
| **Confidence** | How strongly the evidence supports the finding |
| **Evidence** | Relevant output, screenshots, and reproducible observations |
| **Impact** | Realistic security consequences |
| **Remediation** | Practical mitigation or corrective action |
| **Retest** | Verification of the fix, where applicable |

Prioritise findings according to verified exposure, realistic impact, and business context rather than the number of results collected.

## ◈ Roadmap

Potential areas for future development:

- [ ] Consolidated reconnaissance summary
- [ ] Improved result normalisation and deduplication
- [ ] Additional output validation and error handling
- [ ] Configurable research-source selection
- [ ] Report-ready export of validated findings

These are proposed enhancements, not claims about features already implemented.

---

<div align="center">

### ◈ OSINT-RECON

**Gather deliberately. Verify carefully. Report clearly.**

A reconnaissance workflow for authorised security assessments.

</div>
