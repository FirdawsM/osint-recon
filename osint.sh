# osint.sh - source it:  export TARGET=https://www.example.com ; source ~/bin/osint.sh
# Optional: export COMPANY="Example Corp Ltd"   (adds company-name searches)
[ -z "$TARGET" ] && { echo "Run first:  export TARGET=example.com"; return 1 2>/dev/null || exit 1; }
TARGET=${TARGET#*://}; TARGET=${TARGET%%/*}; TARGET=${TARGET#www.}
TARGET=$(printf %s "$TARGET" | tr 'A-Z' 'a-z'); export TARGET
OUT=~/recon/$TARGET; RAW=$OUT/evidence/raw; SHOTS=$OUT/evidence/screenshots; NOTES=$OUT/notes
mkdir -p "$RAW/docs" "$SHOTS" "$NOTES"
[ -f "$NOTES/evidence_log.csv" ] || echo "id,timestamp_eat,what_it_shows,file,sha256" > "$NOTES/evidence_log.csv"

ts(){ TZ=Africa/Nairobi date '+%F %T'; }
hint(){ printf '\n  LOOK FOR: %s\n\n' "$*"; }
n(){ printf -- '- [%s] %s\n' "$(ts)" "$*" >> "$NOTES/notes.md"; echo "  noted: $*"; }
cnt(){ [ -f "$1" ] && wc -l < "$1" || echo 0; }

shot(){  # shot <name> "what it shows"  -> select area, press Enter
  [ -z "$1" ] && { echo 'usage: shot name "what it shows"'; return 1; }
  local f="$SHOTS/$(date +%H%M%S)_$1.png" id h
  if command -v flameshot >/dev/null 2>&1; then flameshot gui -p "$f"
  elif command -v gnome-screenshot >/dev/null 2>&1; then gnome-screenshot -a -f "$f"
  else echo "install flameshot: sudo apt install flameshot"; return 1; fi
  sleep 1; [ -f "$f" ] || { echo "no screenshot saved"; return 1; }
  id=$(printf 'S%02d' $(( $(wc -l < "$NOTES/evidence_log.csv") )))
  h=$(sha256sum "$f" | cut -d' ' -f1)
  echo "$id,$(ts),$(printf %s "$2" | tr ',' ';'),$(basename "$f"),$h" >> "$NOTES/evidence_log.csv"
  n "SCREENSHOT $id $(basename "$f"): $2"
}

o_whois(){ echo "== WHOIS"
  whois "$TARGET" | tee "$RAW/whois.txt" | grep -iE 'registrar:|registrant|creat|expir|updated|name server|org|e-?mail' | head -30
  hint "registrar and dates (near expiry = takeover risk), registrant org/email (real or privacy proxy), name servers (who runs DNS), related emails.  SHOT: whois summary"; }

o_dns(){ echo "== DNS and email posture"
  for t in A AAAA MX NS TXT SOA CAA; do echo "-- $t"; dig +short "$TARGET" $t; done | tee "$RAW/dns.txt"
  local d s
  d=$(dig +short TXT "_dmarc.$TARGET"); s=$(dig +short TXT "$TARGET" | grep -i spf1)
  echo "-- DMARC: $d"; echo "-- SPF: $s"
  for k in default google selector1 selector2 k1 s1 s2 mail dkim; do r=$(dig +short TXT "$k._domainkey.$TARGET"); [ -n "$r" ] && echo "-- DKIM $k found"; done
  echo "-- SaaS verification records"; dig +short TXT "$TARGET" | grep -iE 'verification|ms=|atlassian|docusign|zoom|slack|google-site|adobe|facebook' | tee "$RAW/saas_txt.txt"
  n "MX: $(dig +short MX "$TARGET" | tr '\n' ' ')"
  if [ -z "$d" ]; then n "FINDING: no DMARC record (email spoofing possible)"
  elif echo "$d" | grep -qi 'p=none'; then n "FINDING: DMARC p=none (spoofed mail not blocked)"; fi
  if [ -z "$s" ]; then n "FINDING: no SPF record"
  elif echo "$s" | grep -qE '\+all|\?all|~all'; then n "FINDING: weak SPF: $s"; fi
  [ -s "$RAW/saas_txt.txt" ] && n "SaaS vendors hinted in TXT records (see evidence/raw/saas_txt.txt)"
  hint "DMARC missing or p=none, SPF ending in all-variants, MX vendor (Google/Microsoft/Mimecast = phishing route), TXT verification = SaaS used, CAA missing.  SHOT: mxtoolbox DMARC page or the terminal output"; }

o_subs(){ echo "== Subdomains (passive)"
  curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//' | sort -u > "$RAW/crtsh.txt"
  subfinder -d "$TARGET" -all -silent > "$RAW/subfinder.txt" 2>/dev/null
  amass enum -passive -d "$TARGET" -o "$RAW/amass.txt" >/dev/null 2>&1
  curl -s "http://web.archive.org/cdx/search/cdx?url=*.$TARGET&output=text&fl=original&collapse=urlkey" | sed -E 's#^https?://([^/:]+).*#\1#' | sort -u > "$RAW/wayback_hosts.txt"
  cat "$RAW"/crtsh.txt "$RAW"/subfinder.txt "$RAW"/amass.txt "$RAW"/wayback_hosts.txt 2>/dev/null | tr 'A-Z' 'a-z' | grep -F "$TARGET" | sort -u > "$NOTES/subdomains.txt"
  grep -iE 'dev|test|stage|staging|uat|vpn|admin|portal|old|backup|jenkins|git|api|internal|sso|owa|remote|mail' "$NOTES/subdomains.txt" > "$NOTES/interesting_subdomains.txt"
  echo "unique subdomains: $(wc -l < "$NOTES/subdomains.txt")  interesting: $(wc -l < "$NOTES/interesting_subdomains.txt")"; cat "$NOTES/interesting_subdomains.txt"
  n "Subdomains: $(wc -l < "$NOTES/subdomains.txt") unique, $(wc -l < "$NOTES/interesting_subdomains.txt") interesting (notes/interesting_subdomains.txt)"
  hint "dev/test/staging/vpn/admin/jenkins/git hosts, old hosts only in Wayback, hosts on other companies' names.  SHOT: crt.sh list + the interesting ones"; }

o_resolve(){ echo "== Resolve and CNAME check (DNS lookups only)"
  : > "$NOTES/resolved.txt"; : > "$NOTES/cnames.txt"
  while read -r h; do
    echo "$h $(dig +short "$h" | tail -1)" >> "$NOTES/resolved.txt"
    c=$(dig +short CNAME "$h" | head -1); [ -n "$c" ] && echo "$h -> $c" >> "$NOTES/cnames.txt"
  done < "$NOTES/subdomains.txt"
  grep -iE 'github\.io|azurewebsites|cloudapp|herokuapp|amazonaws|cloudfront|trafficmanager|elasticbeanstalk|fastly|netlify|surge\.sh|bitbucket\.io|readthedocs|statuspage|zendesk|ghost\.io|pantheonsite' "$NOTES/cnames.txt" | tee "$NOTES/takeover_candidates.txt"
  [ -s "$NOTES/takeover_candidates.txt" ] && n "CHECK takeover: $(wc -l < "$NOTES/takeover_candidates.txt") CNAMEs point at third-party services (notes/takeover_candidates.txt)"
  grep -E ' (10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)' "$NOTES/resolved.txt" | tee "$NOTES/private_ip_leaks.txt"
  [ -s "$NOTES/private_ip_leaks.txt" ] && n "FINDING: public DNS leaks private IPs (notes/private_ip_leaks.txt)"
  hint "CNAME to a service that no longer exists = takeover; private IPs in public DNS; IPs outside the client's ranges = shadow IT.  SHOT: the candidate CNAME plus the provider's 'not found' page"; }

o_emails(){ echo "== Emails (theHarvester)"
  theHarvester -d "$TARGET" -b duckduckgo,crtsh,hackertarget,otx,urlscan -l 200 -f "$RAW/theharvester" 2>&1 | tee "$RAW/theharvester.txt" | grep -E '@' | sort -u | tee "$NOTES/emails.txt"
  echo "(if a source name is rejected, run: theHarvester -h)"
  n "Emails found: $(wc -l < "$NOTES/emails.txt") (format: fill in, for example first.last@)"
  hint "the email format, admin/it/finance/hr mailboxes, personal-domain addresses.  Report the format and count, not every name.  SHOT: Hunter.io format page"; }

o_meta(){ echo "== Document metadata (save public PDFs/Office files into $RAW/docs first)"
  exiftool -r -csv -Author -Creator -LastModifiedBy -Producer -Software -Title "$RAW/docs" > "$NOTES/doc_metadata.csv" 2>/dev/null
  cut -d, -f2-6 "$NOTES/doc_metadata.csv" | sort | uniq -c | sort -rn | head -15
  hint "usernames (Author/LastModifiedBy = login format), software versions, internal paths, printer or server names.  SHOT: the exiftool output"; }

o_sites(){ echo "== Opening research sites in small batches (Enter to continue, q to stop)"
  local q; q=$(printf %s "${COMPANY:-$TARGET}" | sed 's/ /+/g')
  local urls=(
   "https://crt.sh/?q=%25.$TARGET"
   "https://www.virustotal.com/gui/domain/$TARGET/relations"
   "https://securitytrails.com/domain/$TARGET/dns"
   "https://dnsdumpster.com/"
   "https://www.shodan.io/search?query=hostname%3A$TARGET"
   "https://search.censys.io/search?resource=hosts&q=$TARGET"
   "https://urlscan.io/search/#page.domain%3A$TARGET"
   "https://mxtoolbox.com/SuperTool.aspx?action=dmarc%3a$TARGET&run=toolpage"
   "https://bgp.he.net/dns/$TARGET"
   "https://web.archive.org/web/*/$TARGET*"
   "https://builtwith.com/$TARGET"
   "https://hunter.io/search/$TARGET"
   "https://haveibeenpwned.com/DomainSearch"
   "https://github.com/search?q=%22$TARGET%22&type=code"
   "https://www.google.com/search?q=site%3A$TARGET+filetype%3Apdf+OR+filetype%3Adocx+OR+filetype%3Axlsx+OR+filetype%3Apptx"
   "https://www.google.com/search?q=site%3A$TARGET+inurl%3Alogin+OR+inurl%3Aadmin+OR+inurl%3Aportal+OR+inurl%3Avpn"
   "https://www.google.com/search?q=site%3A$TARGET+intitle%3A%22index+of%22"
   "https://www.google.com/search?q=site%3A$TARGET+ext%3Abak+OR+ext%3Asql+OR+ext%3Aenv+OR+ext%3Alog"
   "https://www.google.com/search?q=site%3As3.amazonaws.com+OR+site%3Ablob.core.windows.net+OR+site%3Astorage.googleapis.com+%22$TARGET%22"
   "https://www.google.com/search?q=site%3Apastebin.com+OR+site%3Astackoverflow.com+%22$TARGET%22"
   "https://www.google.com/search?q=%22$q%22+jobs+%22experience+with%22+OR+%22knowledge+of%22"
   "https://www.google.com/search?q=%22$q%22+site%3Alinkedin.com%2Fin+IT+OR+security+OR+finance+OR+HR"
  )
  local i=0 n=${#urls[@]} batch=5
  while [ $i -lt $n ]; do
    for j in $(seq 1 $batch); do
      [ $i -ge $n ] && break
      echo "  [$((i+1))/$n] ${urls[$i]}"
      xdg-open "${urls[$i]}" >/dev/null 2>&1
      i=$((i+1)); sleep 1
    done
    [ $i -ge $n ] && break
    printf 'Opened %d/%d. Enter for next batch, q to stop: ' "$i" "$n"
    read -r a; [ "$a" = q ] && { echo "stopped at $i/$n"; return; }
  done; }

o_web(){ echo "== Live web hosts. ACTIVE: sends normal web requests to client servers."
  printf 'Is this allowed in the RoE? [y/N] '; read -r a; case $a in y|Y) ;; *) return 1;; esac
  local H; H=$(command -v httpx-toolkit || command -v httpx)
  [ -z "$H" ] && { echo "install: sudo apt install httpx-toolkit"; return 1; }
  "$H" -l "$NOTES/subdomains.txt" -silent -title -status-code -tech-detect -web-server -o "$RAW/httpx.txt"; cat "$RAW/httpx.txt"
  n "Live web hosts: $(wc -l < "$RAW/httpx.txt") (evidence/raw/httpx.txt)"
  hint "login/admin panels, default pages, old software versions, 401/403 on interesting hosts, dev/staging sites that are live.  SHOT: the interesting hosts in the browser"; }

o_summary(){ echo; echo "== SUMMARY: $TARGET"
  echo "subdomains: $(cnt "$NOTES/subdomains.txt") | emails: $(cnt "$NOTES/emails.txt") | screenshots: $(( $(wc -l < "$NOTES/evidence_log.csv") - 1 ))"
  echo "-- notes ($NOTES/notes.md)"; cat "$NOTES/notes.md" 2>/dev/null; }

o_all(){ o_whois; o_dns; o_subs; o_resolve; o_emails; o_summary; }

echo "Ready: $TARGET  ->  $OUT"
echo "Run:  o_all   then  o_sites   (o_web = active, o_meta = documents, o_summary = recap)"
echo "Any time:  n \"note\"    shot name \"what it shows\""
