# osint-recon

A set of shell functions for running passive OSINT reconnaissance during authorised security engagements. Set the target once, then every command is ready to run — no editing commands by hand.

**For authorised engagements only.** This tool is for assessing what an attacker could learn about an organisation from public information, as part of a signed, scoped engagement. It is not for targeting anyone without written authorization.

## What it does

- Passive WHOIS, DNS, and email-authentication checks (SPF, DMARC, DKIM)
- Subdomain enumeration from certificate transparency, passive DNS, and web archives
- CNAME / subdomain-takeover candidate checks
- Email address discovery (theHarvester)
- Document metadata extraction (exiftool)
- Opens a batch of research sites (crt.sh, Shodan, Censys, VirusTotal, GitHub code search, targeted Google dorks) a few tabs at a time
- An opt-in active check (`o_web`) that fingerprints live web hosts — asks for confirmation before running, since it sends real requests to the target's servers
- Auto-logs notes and likely findings as it goes, and tracks screenshots with a timestamp and SHA-256 hash for evidence integrity

## Requirements (Kali / Debian-based)

```bash
sudo apt install -y subfinder amass theharvester httpx-toolkit libimage-exiftool-perl flameshot jq curl dnsutils whois
```

## Install

```bash
mkdir -p ~/bin
cp osint.sh ~/bin/osint.sh
chmod +x ~/bin/osint.sh
```

Add an alias so it's always available (Kali's default shell is zsh):

```bash
echo 'alias recon="source ~/bin/osint.sh"' >> ~/.zshrc
source ~/.zshrc
```

(If you use bash instead, add the same line to `~/.bashrc`.)

## Usage

```bash
export TARGET=https://www.example.com    # a full URL is fine, it strips to the domain
export COMPANY="Example Corp Ltd"        # optional, used for company-name searches
recon
```

Then run, roughly in this order:

| Command | What it does |
| --- | --- |
| `o_whois` | WHOIS lookup |
| `o_dns` | DNS records, SPF/DMARC/DKIM, SaaS hints from TXT records |
| `o_subs` | Passive subdomain enumeration |
| `o_resolve` | Resolves subdomains, flags CNAME takeover candidates |
| `o_emails` | Email discovery via theHarvester |
| `o_all` | Runs the five above in order |
| `o_sites` | Opens research sites in batches of 5, pauses between each |
| `o_meta` | Document metadata (save public PDFs/Office files into `evidence/raw/docs` first) |
| `o_web` | **Active.** Fingerprints live web hosts. Asks for confirmation first |
| `o_summary` | Recap of counts and notes so far |

Anywhere, anytime:

```bash
n "a note to add"
shot a_short_name "what the screenshot shows"
```

`shot` opens a screen-area selector, saves the image, and logs it with a timestamp and hash automatically.

## Output

Everything is written to `~/recon/<domain>/`:

```
evidence/
  raw/        tool output (whois, dns, subdomain lists, etc.)
  screenshots/
notes/
  notes.md              running notes and auto-flagged findings
  evidence_log.csv       screenshot log with hashes
  subdomains.txt, interesting_subdomains.txt, resolved.txt, cnames.txt, emails.txt
```

## Known limitations

- `o_dns` relies on your local resolver. If it's broken or unreachable (common on VM NAT setups), DMARC/DKIM results can be wrong or missing. Verify against a public resolver if in doubt: `dig @8.8.8.8 +short TXT _dmarc.DOMAIN`.
- theHarvester occasionally returns a result tied to its own test data rather than the target — sanity-check anything unexpected before reporting it.
- `o_web` is active: it sends real HTTP requests to the target's servers. Only run it when your rules of engagement explicitly allow it, and confirm the testing window with the client first.
- GitHub code search, LinkedIn, and some other sites opened by `o_sites` require you to be logged in.

## Report template

Pair this with a findings/report template of your own. A good structure: executive summary, scope, methodology, findings (rating + confidence + evidence + attacker impact + recommendation), attack chains, and prioritised recommendations.
