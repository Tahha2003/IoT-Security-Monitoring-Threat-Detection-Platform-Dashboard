# IoT Security Monitoring & Threat Detection Platform

<div align="center">

![Dashboard Preview](https://img.shields.io/badge/Status-Live%20Demo-brightgreen?style=for-the-badge)
![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?style=for-the-badge&logo=node.js&logoColor=white)
![React](https://img.shields.io/badge/React-18.2-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

**A real-time IoT Intrusion Detection System (IDS) with ML-based threat classification, automated SOAR response, and a live monitoring dashboard.**

[🚀 Live Demo](https://iot-security-monitoring-threat-detection-platform-dashboard.vercel.app) &nbsp;|&nbsp; [📺 Watch Attack Simulation](#demo-walkthrough) &nbsp;|&nbsp; [⚙️ Run Locally](#running-the-demo-locally)

</div>

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Dashboard Features](#dashboard-features)
- [Demo vs Real System](#demo-vs-real-system-comparison)
- [Tech Stack](#tech-stack)
- [Running the Demo Locally](#running-the-demo-locally)
- [Attack Simulation Script](#attack-simulation-script)
- [Real System Deployment](#real-system-deployment)
- [Project Structure](#project-structure)
- [FYP Context](#fyp-context)

---

## Project Overview

This platform monitors IoT network traffic in real time, detects malicious activity using trained Machine Learning models, and automatically responds through a SOAR (Security Orchestration, Automation and Response) engine.

The system was built as a **Final Year Project (FYP)** and targets real-world smart-home / enterprise IoT environments where traditional network security tools fall short — IoT devices speak unusual protocols (MQTT, CoAP, RTSP), have no agent support, and are frequently targeted.

**What it detects:**
- Port scans and network reconnaissance
- MQTT flood and CoAP amplification attacks
- Brute force (SSH, Telnet)
- Camera feed hijacking and RTSP exploits
- ARP spoofing and man-in-the-middle attacks
- DoS / SYN flood attacks
- C2 beaconing and botnet callbacks
- Data exfiltration from compromised IoT devices
- Lateral movement across the internal network

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        REAL SYSTEM                              │
│                                                                 │
│  IoT Devices ──► Raspberry Pi (SPAN tap)                        │
│                       │                                         │
│                       ▼                                         │
│              Zeek (packet capture)                              │
│                       │                                         │
│                       ▼                                         │
│           Flow Service (feature extraction)                     │
│                       │                                         │
│                       ▼                                         │
│      ML Engine ◄──────┤──────► SIEM (PostgreSQL)               │
│  (Random Forest +     │                                         │
│   Isolation Forest)   ▼                                         │
│                  SOAR Engine ──► Auto-response actions          │
│                       │         (block IP, quarantine device)   │
│                       ▼                                         │
│              FastAPI Backend ──► React Dashboard                │
│              (REST + WebSocket)   (real-time alerts)            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      DEMO VERSION                               │
│                                                                 │
│         node demo-server.js (single Node.js process)           │
│         ├── Port 3000 → Serves React dashboard (static)        │
│         ├── Port 8000 → Mock REST API + WebSocket              │
│         └── Port 9090 → Mock Prometheus metrics                │
│                                                                 │
│         Pre-seeded with ~60–120 realistic alerts               │
│         New alert streamed via WebSocket every 4 seconds       │
│         Metrics drift slowly to simulate real system load      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Dashboard Features

| Panel | Description |
|-------|-------------|
| **Live Alert Feed** | Real-time WebSocket-fed table — src IP, dst IP, attack type, severity, risk score, protocol, timestamp |
| **All Alerts** | Full alert history with filters by severity, attack type, and source IP |
| **Severity Distribution** | Pie/bar chart breakdown across CRITICAL / HIGH / MEDIUM / LOW |
| **Attack Timeline** | Time-series area chart showing alert volume over the last 60 minutes |
| **Top Attacker IPs** | Ranked leaderboard of most active source IPs |
| **Connected Devices** | Live view of IoT devices on the network (IP Camera, BYOD Mobile, Raspberry Pi, etc.) |
| **Network Topology** | Visual diagram of the detection architecture — SPAN port, capture zone, IoT devices |
| **System Health** | CPU usage, inference latency, queue depth, packet loss — pulled from Prometheus |
| **SOAR Playbooks** | 4 toggleable automated response playbooks (Block Attacker, Camera Defense, Quarantine Device, Scan Detection) |
| **Playbook Execution Log** | Timestamped log of every SOAR action taken |
| **System Logs** | Tabbed viewer for startup, pipeline, ML, Zeek, parser, SOAR, API, and training logs |
| **Services Status** | Health indicators for IDS Pipeline, Zeek, PostgreSQL, ML Models |
| **System Control** | Start / Stop pipeline, trigger model retraining, reset firewall, clear database |

---

## Demo vs Real System Comparison

This repository contains the **demo version** of the platform. Here is a detailed comparison between what runs in the demo and what the full real-time system does.

| Aspect | Demo Version | Real System |
|--------|-------------|-------------|
| **Backend** | `demo-server.js` — single Node.js file, zero dependencies beyond Node built-ins | FastAPI (Python) with Uvicorn, multi-service microarchitecture |
| **Packet Capture** | Not applicable — data is simulated | Zeek IDS on a Raspberry Pi with SPAN port tap capturing live traffic |
| **ML Inference** | Simulated — random alerts with realistic distributions | Random Forest + Isolation Forest models trained on NSL-KDD / custom IoT dataset, running inference on every captured flow |
| **Alert Storage** | In-memory (array, capped at 2000) — resets on restart | PostgreSQL (`fyp_security` database) with persistent storage and batch writes |
| **WebSocket** | Hand-rolled RFC 6455 in Node.js — pushes a new alert every 4s | Python `websockets` library — pushes alerts immediately on ML classification |
| **Prometheus Metrics** | Mock server with drifting random values | Real `prometheus_client` exporting CPU, queue, latency metrics from the pipeline |
| **SOAR Actions** | Toggles an in-memory boolean — no real action | Executes firewall rules (`iptables`), sends alerts, quarantines devices on the network |
| **Network Topology** | Static pre-defined nodes | Dynamically updates as devices are seen on the network |
| **Data Freshness** | ~60–120 seeded alerts + 1 new alert every 4s | Continuous real-time — alert rate depends on actual network traffic |
| **Protocols Monitored** | Shown in dashboard labels only | TCP, UDP, MQTT, CoAP, RTSP, DNS, NTP, HTTP/S, ICMP, ARP live capture |
| **Hardware Required** | None — runs on any machine with Node.js | Raspberry Pi 4 (SPAN tap), Backend PC (Linux), PostgreSQL, network switch with mirroring |
| **Setup Time** | ~10 seconds (`node demo-server.js`) | ~2–3 hours (network setup, DB init, Zeek config, model training) |
| **IoT Device Simulation** | IP Camera (`192.168.50.10`) and BYOD Mobile (`192.168.50.40`) appear as alert sources/targets | Real devices on the monitored LAN segment |
| **Attack Simulation** | `fake-attack.ps1` / `fake-attack.sh` — theatrical terminal output only | Actual attack tools (nmap, hping3, Hydra) run against test devices in an isolated lab network |

### Key architectural difference

In the real system, every packet captured by Zeek is parsed by the Flow Service, features are extracted (38 network features per flow), and a prediction is made by the ML engine within milliseconds. The SOAR engine then reads the alert severity and executes the matching playbook automatically — no human click needed.

In the demo, `demo-server.js` replaces that entire pipeline with pre-seeded realistic data and a 4-second streaming interval, so the dashboard UI behaves identically to what you would see in a live deployment.

---

## Tech Stack

### Demo
| Layer | Technology |
|-------|-----------|
| Mock Backend | Node.js (built-ins only: `http`, `fs`, `path`, `crypto`) |
| Frontend | React 18.2, Recharts 2.10 |
| Build Tool | Create React App (react-scripts 5) |

### Real System
| Layer | Technology |
|-------|-----------|
| Packet Capture | Zeek IDS 6.x |
| Backend API | FastAPI 0.135 + Uvicorn |
| ML Engine | scikit-learn 1.7 (Random Forest, Isolation Forest), pandas, numpy |
| Database | PostgreSQL 15 + psycopg2 |
| Metrics | Prometheus client |
| Packet Analysis | Scapy |
| Frontend | React 18.2, Recharts 2.10 |
| OS | Ubuntu 22.04 LTS (backend PC + Raspberry Pi) |

---

## Running the Demo Locally

### Prerequisites
- [Node.js](https://nodejs.org/) v18 or higher

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Tahha2003/IoT-Security-Monitoring-Threat-Detection-Platform-Dashboard.git
cd IoT-Security-Monitoring-Threat-Detection-Platform-Dashboard

# 2. Start the demo server
node demo-server.js

# 3. Open your browser
# http://localhost:3000
```

**Windows users** — you can also double-click `START-DEMO.bat` which automatically opens the browser for you.

The server starts three services:
- `http://localhost:3000` — Dashboard UI
- `http://localhost:8000` — REST API (alerts, SOAR, system status)
- `http://localhost:9090` — Prometheus metrics mock

> No `npm install` needed. The React app is pre-built in `dashboard/build/` and served statically by `demo-server.js`.

---

## Attack Simulation Script

To make the demo presentation more dramatic, run the attack simulation script on a second screen while the dashboard is visible on the main screen. New alerts will appear on the dashboard in real time.

**Windows (PowerShell):**
```powershell
.\fake-attack.ps1
```

**Linux / macOS:**
```bash
bash fake-attack.sh
```

The script simulates a full 7-phase attack chain:

```
Phase 1 — Network Reconnaissance   (nmap scan, host discovery)
Phase 2 — IoT Device Fingerprinting (camera RTSP, mobile ADB)
Phase 3 — Camera RTSP Exploit       (CVE-2021-36260 buffer overflow)
Phase 4 — MQTT Flood                (5000 msg/sec botnet flood)
Phase 5 — SSH Brute Force           (Hydra — credentials found)
Phase 6 — C2 Beacon + Exfiltration  (SSH session, pg_dump exfil)
Phase 7 — Lateral Movement          ⛔ BLOCKED by IDS/SOAR
```

> This script produces **theatrical terminal output only** — it does not send any real network traffic. It is purely for visual effect during a presentation.

---

## Real System Deployment

> ⚠️ The real deployment requires dedicated hardware and a Linux environment.

### Hardware
- Raspberry Pi 4 (4GB RAM) — network tap, Zeek capture
- Backend PC — FastAPI, PostgreSQL, ML engine (Ubuntu 22.04)
- Network switch with port mirroring (SPAN) support

### Quick Setup

```bash
# 1. Install Python dependencies
pip install -r requirements.txt   # (restore from git history if needed)

# 2. Set environment variables
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=fyp_security
export DB_USER=postgres
export DB_PASS=your_password

# 3. Initialise the database
sudo -u postgres psql -c "CREATE DATABASE fyp_security;"

# 4. Build the dashboard with your backend IP
cd dashboard
cp .env.example .env
# Edit .env: set REACT_APP_API_URL=http://<your-backend-ip>:8000
npm install
npm run build
cd ..

# 5. Start the real pipeline
bash infrastructure/scripts/start_pipeline.sh
```

---

## Project Structure

```
.
├── demo-server.js          # Complete demo backend (mock API + WebSocket + Prometheus)
├── START-DEMO.bat          # Windows one-click launcher
├── START-DEMO.ps1          # PowerShell launcher
├── fake-attack.ps1         # Theatrical attack simulator (Windows)
├── fake-attack.sh          # Theatrical attack simulator (Linux/macOS)
├── dashboard/
│   ├── build/              # Pre-built React app (served by demo-server.js)
│   ├── package.json        # React app dependencies
│   ├── .env.example        # Environment config template
│   └── README.md           # CRA default readme
└── .gitignore
```

---

## FYP Context

This project was developed as a **Final Year Project** for a Bachelor's degree in Computer Science / Cybersecurity.

**Problem Statement:** IoT devices are inherently insecure — they run minimal firmware, expose unencrypted protocols, and cannot run traditional endpoint security agents. Existing network IDS solutions are not optimised for IoT traffic patterns, leading to high false-positive rates and missed attacks.

**Proposed Solution:** A network-tap-based passive monitoring system that:
1. Captures traffic without modifying device firmware
2. Extracts flow-level features from IoT-specific protocols
3. Classifies traffic using ML models trained on IoT attack datasets
4. Automates response through SOAR playbooks without human intervention

**Results (real system):**
- Random Forest: ~97% detection accuracy, ~2.1% false positive rate
- Isolation Forest: effective at flagging zero-day / anomalous behaviour
- Average inference latency: < 8ms per flow
- SOAR response time: < 500ms from detection to firewall rule enforcement

---

<div align="center">

Built with ❤️ as a Final Year Project &nbsp;|&nbsp; [GitHub](https://github.com/Tahha2003/IoT-Security-Monitoring-Threat-Detection-Platform-Dashboard)

</div>
