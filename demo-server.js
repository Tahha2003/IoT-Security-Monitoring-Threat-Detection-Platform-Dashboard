/**
 * IoT Threat Detection — DEMO MOCK SERVER
 * ========================================
 * Single-port server — works locally AND on Render/Railway.
 *
 * All traffic runs on ONE port (process.env.PORT || 3000):
 *   /api/*            → REST API  (alerts, SOAR, system control)
 *   /ws               → WebSocket live alert feed
 *   /prom/*           → Prometheus metrics mock
 *   /* (everything else) → React SPA (dashboard/build)
 *
 * Features:
 *   - 60-120 pre-seeded realistic IoT alerts
 *   - WebSocket streams a new alert every 4 seconds
 *   - Prometheus metrics drift slowly
 *   - Full CORS headers
 *   - Zero external dependencies — Node.js built-ins only
 */

'use strict';

const http   = require('http');
const fs     = require('fs');
const path   = require('path');
const url    = require('url');
const crypto = require('crypto');

// ─────────────────────────────────────────────────────────────────────────────
// 1.  DEMO DATA
// ─────────────────────────────────────────────────────────────────────────────

const ATTACK_TYPES = [
  'Port Scan', 'MQTT Flood', 'Brute Force SSH', 'ARP Spoofing',
  'DoS - SYN Flood', 'Camera Feed Hijack', 'RTSP Exploit',
  'DNS Amplification', 'ICMP Flood', 'CoAP Amplification',
  'Telnet Brute Force', 'Modbus Injection',
];

const IOT_ATTACK_TYPES = [
  'C2 Beacon', 'Botnet C2 Callback', 'Data Exfiltration',
  'MQTT Publish Flood', 'Mirai Variant Activity', 'Lateral Movement',
  'DNS Tunneling', 'Reverse Shell', 'Credential Stuffing',
];

const SEVERITIES = ['CRITICAL', 'HIGH', 'HIGH', 'MEDIUM', 'MEDIUM', 'MEDIUM', 'LOW'];
const PROTOS     = ['TCP', 'UDP', 'TCP', 'TCP', 'UDP', 'MQTT', 'RTSP', 'ICMP'];

const ATTACKER_IPS = ['10.0.0.77', '10.0.0.88', '45.33.32.156', '185.220.101.34'];

const IOT_DEVICE_IPS = [
  '192.168.50.10',  // IP Camera
  '192.168.50.40',  // BYOD Mobile
];

const INTERNAL_VICTIM_IPS = [
  '192.168.1.43', '192.168.1.1', '192.168.10.120', '192.168.10.130',
];

const VICTIM_IPS = [...IOT_DEVICE_IPS, ...INTERNAL_VICTIM_IPS];
const DST_PORTS  = [22, 80, 443, 1883, 8883, 554, 5683, 502, 23, 8080, 9090, 161];

function randItem(arr)              { return arr[Math.floor(Math.random() * arr.length)]; }
function randFloat(min, max, dp=2)  { return parseFloat((Math.random()*(max-min)+min).toFixed(dp)); }
function randInt(min, max)          { return Math.floor(Math.random()*(max-min+1))+min; }
function makeTimestamp(minsAgo)     { return new Date(Date.now() - minsAgo*60*1000).toISOString(); }

function severityToRisk(sev) {
  switch (sev) {
    case 'CRITICAL': return randFloat(0.82, 0.99);
    case 'HIGH':     return randFloat(0.62, 0.81);
    case 'MEDIUM':   return randFloat(0.38, 0.61);
    default:         return randFloat(0.10, 0.37);
  }
}

let alertIdCounter = 1;

function makeAlert(minsAgo=0) {
  const severity = randItem(SEVERITIES);
  const proto    = randItem(PROTOS);
  return {
    id: alertIdCounter++, timestamp: makeTimestamp(minsAgo),
    src_ip: randItem(ATTACKER_IPS), dst_ip: randItem(VICTIM_IPS),
    dst_port: randItem(DST_PORTS), proto,
    attack_type: randItem(ATTACK_TYPES), severity,
    risk_score: severityToRisk(severity),
    src_port: randInt(1024,65535), payload_len: randInt(40,1400),
    flags: proto==='TCP' ? randItem(['SYN','SYN-ACK','PSH-ACK','RST']) : null,
    confidence: randFloat(0.75,0.99),
  };
}

function makeIoTAlert(minsAgo=0) {
  const severity = randItem(['CRITICAL','HIGH','HIGH','MEDIUM','MEDIUM']);
  const proto    = randItem(['TCP','UDP','MQTT','TCP','TCP']);
  return {
    id: alertIdCounter++, timestamp: makeTimestamp(minsAgo),
    src_ip: randItem(IOT_DEVICE_IPS),
    dst_ip: Math.random()<0.5 ? randItem(ATTACKER_IPS) : randItem(INTERNAL_VICTIM_IPS),
    dst_port: randItem([443,8080,4444,1883,80,53,6667]), proto,
    attack_type: randItem(IOT_ATTACK_TYPES), severity,
    risk_score: severityToRisk(severity),
    src_port: randInt(1024,65535), payload_len: randInt(40,800),
    flags: proto==='TCP' ? randItem(['PSH-ACK','SYN','RST']) : null,
    confidence: randFloat(0.78,0.97),
  };
}

function makeIoTInboundAlert(minsAgo=0) {
  const severity  = randItem(['CRITICAL','CRITICAL','HIGH','HIGH','MEDIUM']);
  const iotTarget = randItem(IOT_DEVICE_IPS);
  const attack    = iotTarget==='192.168.50.10'
    ? randItem(['Camera Feed Hijack','RTSP Exploit','ONVIF Exploit','Port Scan','Brute Force SSH'])
    : randItem(['Telnet Brute Force','Brute Force SSH','ARP Spoofing','DoS - SYN Flood','MQTT Flood']);
  const proto     = iotTarget==='192.168.50.10' ? randItem(['TCP','RTSP','UDP']) : randItem(['TCP','UDP']);
  const dst_port  = iotTarget==='192.168.50.10' ? randItem([554,80,8080,22]) : randItem([23,22,443,80]);
  return {
    id: alertIdCounter++, timestamp: makeTimestamp(minsAgo),
    src_ip: randItem(ATTACKER_IPS), dst_ip: iotTarget,
    dst_port, proto, attack_type: attack, severity,
    risk_score: severityToRisk(severity),
    src_port: randInt(1024,65535), payload_len: randInt(100,1200),
    flags: proto==='TCP' ? randItem(['SYN','SYN-ACK','PSH-ACK']) : null,
    confidence: randFloat(0.80,0.99),
  };
}

// Seed ~60-120 alerts over last 60 minutes
const alertStore = [];
for (let i=60; i>=1; i--) {
  const roll = Math.random();
  if      (roll < 0.35) alertStore.push(makeIoTInboundAlert(i + randFloat(0,0.9)));
  else if (roll < 0.60) alertStore.push(makeIoTAlert(i + randFloat(0,0.9)));
  else {
    const count = randInt(1,3);
    for (let j=0; j<count; j++) alertStore.push(makeAlert(i + randFloat(0,0.9)));
  }
}
alertStore.sort((a,b) => new Date(b.timestamp) - new Date(a.timestamp));

// ─────────────────────────────────────────────────────────────────────────────
// 2.  PROMETHEUS METRICS  (drift every 3s)
// ─────────────────────────────────────────────────────────────────────────────

const metrics = { cpu:42.5, queue:3, latency:18.4, packetLoss:0.3 };

setInterval(() => {
  metrics.cpu        = Math.min(95,  Math.max(5,   metrics.cpu        + randFloat(-3,3)));
  metrics.queue      = Math.min(20,  Math.max(0,   metrics.queue      + randFloat(-1,2)));
  metrics.latency    = Math.min(120, Math.max(5,   metrics.latency    + randFloat(-2,3)));
  metrics.packetLoss = Math.min(5,   Math.max(0,   metrics.packetLoss + randFloat(-0.1,0.2)));
}, 3000);

// ─────────────────────────────────────────────────────────────────────────────
// 3.  SOAR STATE
// ─────────────────────────────────────────────────────────────────────────────

const playbookState = {
  block_attacker:    { id:'block_attacker',    name:'Block Attacker',    enabled:true },
  camera_defense:    { id:'camera_defense',    name:'Camera Defense',    enabled:true },
  quarantine_device: { id:'quarantine_device', name:'Quarantine Device', enabled:true },
  scan_detection:    { id:'scan_detection',    name:'Scan Detection',    enabled:true },
};

const ACTION_PLAYBOOK_MAP = {
  BLOCKED:'block_attacker',  RATE_LIMITED:'camera_defense',
  QUARANTINED:'quarantine_device', SCAN_DETECTED:'scan_detection',
  LOGGED:'scan_detection',   ALREADY_QUARANTINED:'quarantine_device',
  COOLDOWN:'block_attacker',
};

const SOAR_DETAILS = {
  BLOCKED:            ['UFW deny rule added: deny from {ip}','iptables -A INPUT -s {ip} -j DROP','Attacker IP added to blocklist'],
  RATE_LIMITED:       ['Rate limit: 10 req/s on port 554','iptables rate-limit applied to camera subnet','RTSP connection throttled'],
  QUARANTINED:        ['Device isolated — allow list: backend only','VLAN reassigned to quarantine segment','All outbound blocked except port 8000'],
  SCAN_DETECTED:      ['Port scan: 47 ports probed in 2.1s','Nmap-style scan detected from {ip}','SYN scan pattern identified'],
  LOGGED:             ['Event logged to SIEM','Alert forwarded to analyst dashboard','Threat intel feed updated'],
  ALREADY_QUARANTINED:['Device already in quarantine — skipped','Rule already exists, cooldown 30s'],
  COOLDOWN:           ['Cooldown active (30s remaining)','Rate limit: duplicate action suppressed'],
};

function makeSoarEntry(minsAgo=0) {
  const action   = randItem(Object.keys(ACTION_PLAYBOOK_MAP));
  const playbook = ACTION_PLAYBOOK_MAP[action];
  const src_ip   = randItem([...ATTACKER_IPS,...IOT_DEVICE_IPS]);
  const message  = randItem(SOAR_DETAILS[action]||['Action executed']).replace('{ip}',src_ip);
  return {
    timestamp: makeTimestamp(minsAgo), src_ip,
    risk: randFloat(0.55,0.99),
    results: [{ playbook, action, message }],
  };
}

const soarLog = [];
for (let i=20; i>=1; i--) soarLog.push(makeSoarEntry(i*2.5 + randFloat(0,1)));
soarLog.sort((a,b) => new Date(b.timestamp) - new Date(a.timestamp));

// ─────────────────────────────────────────────────────────────────────────────
// 4.  FAKE LOG LINES
// ─────────────────────────────────────────────────────────────────────────────

const LOG_LINES = {
  startup:  ['[INFO]  Starting IoT IDS pipeline...','[INFO]  Loading ML models from ml/training/models/','[INFO]  rf_model.pkl loaded (RandomForest, 150 estimators)','[INFO]  iso_model.pkl loaded (IsolationForest)','[INFO]  preprocessor.pkl loaded','[INFO]  PostgreSQL connected — fyp_security database ready','[INFO]  Zeek started on interface eth0','[INFO]  Pipeline threads spawned (7 workers)','[INFO]  SIEM writer ready (batch size: 50)','[OK]    All systems nominal — IDS ACTIVE'],
  pipeline: ['[PIPELINE] Flow collector running on 0.0.0.0:9000','[PIPELINE] Packet queue depth: 3','[PIPELINE] Processed 1420 flows in last 10s','[PIPELINE] ML inference batch: 50 samples @ 18ms avg latency','[PIPELINE] Alert generated: Port Scan from 10.0.0.77','[PIPELINE] Alert generated: MQTT Flood from 10.0.0.88','[PIPELINE] Flow buffer flush — 312 flows written to DB','[PIPELINE] Zeek log rotation completed','[PIPELINE] Feature extraction: 87 features per flow','[PIPELINE] Thread-3 idle — waiting for flows'],
  ml:       ['[ML] RandomForest prediction: CRITICAL (conf=0.97)','[ML] IsolationForest anomaly score: -0.42 (anomalous)','[ML] Batch processed: 50 samples in 18.3ms','[ML] Feature drift detected — retraining recommended','[ML] Model loaded: rf_model.pkl (v2.1)','[ML] Prediction: Port Scan — risk_score=0.94','[ML] Prediction: Normal — risk_score=0.12','[ML] Confusion matrix (last 1000): TP=982, FP=8, FN=10','[ML] Precision: 0.992 | Recall: 0.989 | F1: 0.990','[ML] Next scheduled retrain: 2026-08-21 02:00:00'],
  zeek:     ['[ZEEK] Started on interface: eth0','[ZEEK] conn.log: 1240 new entries','[ZEEK] dns.log: 87 queries logged','[ZEEK] http.log: 34 HTTP transactions','[ZEEK] ntp.log: 12 NTP packets','[ZEEK] mqtt_publish.log: 56 MQTT publishes','[ZEEK] Suspicious SCAN from 10.0.0.77 — 47 ports','[ZEEK] notice.log: SCAN::Port_Scan triggered','[ZEEK] Capture loss: 0.2% (within acceptable range)','[ZEEK] Flow exported to pipeline — 1420 flows'],
  parser:   ['[PARSER] DPI engine: Suricata 7.0 active','[PARSER] Rule set: emerging-threats (42310 rules)','[PARSER] Matched rule: ET SCAN Potential SSH Scan','[PARSER] Matched rule: ET DOS Potential MQTT Flood','[PARSER] Protocol: RTSP detected on port 554','[PARSER] Protocol: MQTT on port 1883 — payload inspected','[PARSER] Deep packet inspection: 312 flows analysed','[PARSER] Suricata alert: GPL ATTACK_RESPONSE id check returned root','[PARSER] Payload fingerprint: Mirai variant (confidence 0.81)','[PARSER] Parser queue: 2 pending batches'],
  soar:     ['[SOAR] Playbook triggered: block_attacker → 10.0.0.77','[SOAR] UFW rule added: deny from 10.0.0.77','[SOAR] Playbook triggered: camera_defense → 192.168.50.10','[SOAR] Rate limit applied: iptables -A INPUT -s 10.0.0.77 -m limit','[SOAR] Cooldown active for 10.0.0.88 (30s remaining)','[SOAR] Playbook scan_detection: port scan logged','[SOAR] Action: BLOCKED — attacker IP added to deny list','[SOAR] Notification sent to analyst dashboard','[SOAR] Playbook quarantine_device: DISABLED (skipped)','[SOAR] 3 actions executed in last 60s'],
  api:      ['[API]  GET /api/alerts?limit=20 → 200 OK (12ms)','[API]  WS /ws → client connected','[API]  GET /api/system/status → 200 OK (5ms)','[API]  POST /api/system/start → 200 OK pipeline started','[API]  GET /api/soar/log → 200 OK (8ms)','[API]  WS → alert pushed to 1 connected client','[API]  GET /api/alerts/all?limit=500 → 200 OK (34ms)','[API]  GET /api/system/logs/pipeline → 200 OK','[API]  POST /api/soar/playbooks/block_attacker → toggled','[API]  Uptime: 1h 23m 11s | Requests served: 4821'],
  training: ['[TRAIN] Dataset loaded: ml/datasets/balanced_dataset.csv','[TRAIN] Samples: 250,000 | Features: 87 | Classes: 13','[TRAIN] Train/test split: 80/20','[TRAIN] RandomForest training started (150 estimators)...','[TRAIN] IsolationForest training started (contamination=0.05)...','[TRAIN] RandomForest done — accuracy: 99.1%','[TRAIN] IsolationForest done — anomaly threshold: -0.38','[TRAIN] Models saved to ml/training/models/','[TRAIN] Preprocessor saved: preprocessor.pkl','[TRAIN] Training complete in 47.2s'],
};

// ─────────────────────────────────────────────────────────────────────────────
// 5.  WebSocket BROADCASTER  (RFC 6455, no external deps)
// ─────────────────────────────────────────────────────────────────────────────

class WSBroadcaster {
  constructor() { this.sockets = new Set(); }
  add(s)    { this.sockets.add(s); }
  remove(s) { this.sockets.delete(s); }

  encode(data) {
    const payload = Buffer.from(data, 'utf8');
    const len = payload.length;
    let header;
    if (len < 126) {
      header = Buffer.alloc(2);
      header[0] = 0x81;
      header[1] = len;
    } else if (len < 65536) {
      header = Buffer.alloc(4);
      header[0] = 0x81; header[1] = 126;
      header.writeUInt16BE(len, 2);
    } else {
      header = Buffer.alloc(10);
      header[0] = 0x81; header[1] = 127;
      header.writeBigUInt64BE(BigInt(len), 2);
    }
    return Buffer.concat([header, payload]);
  }

  broadcast(obj) {
    const frame = this.encode(JSON.stringify(obj));
    for (const s of this.sockets) {
      try { s.write(frame); } catch (_) { this.sockets.delete(s); }
    }
  }
}

const broadcaster = new WSBroadcaster();

function doWsHandshake(req, socket) {
  const key    = req.headers['sec-websocket-key'];
  const accept = crypto.createHash('sha1')
    .update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
    .digest('base64');

  socket.write(
    'HTTP/1.1 101 Switching Protocols\r\n' +
    'Upgrade: websocket\r\n' +
    'Connection: Upgrade\r\n' +
    `Sec-WebSocket-Accept: ${accept}\r\n\r\n`
  );

  broadcaster.add(socket);
  console.log(`[WS] Client connected  (total: ${broadcaster.sockets.size})`);

  // Push last 10 alerts immediately so the feed isn't empty on load
  for (const alert of alertStore.slice(0,10).reverse()) {
    try { socket.write(broadcaster.encode(JSON.stringify(alert))); } catch (_) {}
  }

  socket.on('end',   () => { broadcaster.remove(socket); console.log('[WS] Client disconnected.'); });
  socket.on('error', () => broadcaster.remove(socket));
  socket.on('data',  () => {});  // ignore incoming frames
}

// ─────────────────────────────────────────────────────────────────────────────
// 6.  HELPERS
// ─────────────────────────────────────────────────────────────────────────────

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin',  '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function jsonReply(res, data, status=200) {
  setCors(res);
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

// ─────────────────────────────────────────────────────────────────────────────
// 7.  STATIC FILE SERVER helpers
// ─────────────────────────────────────────────────────────────────────────────

const MIME = {
  '.html':'text/html; charset=utf-8', '.js':'application/javascript; charset=utf-8',
  '.css':'text/css; charset=utf-8',   '.json':'application/json',
  '.png':'image/png',                 '.ico':'image/x-icon',
  '.svg':'image/svg+xml',             '.map':'application/json',
};

const BUILD_DIR = path.join(__dirname, 'dashboard', 'build');

function serveStatic(reqUrl, res) {
  let filePath = path.join(BUILD_DIR, url.parse(reqUrl).pathname);
  if (!path.extname(filePath)) filePath = path.join(BUILD_DIR, 'index.html');

  const mimeType = MIME[path.extname(filePath).toLowerCase()] || 'application/octet-stream';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      fs.readFile(path.join(BUILD_DIR, 'index.html'), (err2, html) => {
        if (err2) { res.writeHead(500); res.end('Server error'); return; }
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(html);
      });
      return;
    }
    res.writeHead(200, { 'Content-Type': mimeType });
    res.end(data);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 8.  UNIFIED HTTP SERVER  (single port — handles API + Prom + static)
// ─────────────────────────────────────────────────────────────────────────────

const server = http.createServer((req, res) => {
  const parsed   = url.parse(req.url, true);
  const pathname = parsed.pathname;
  const query    = parsed.query;

  // CORS preflight
  if (req.method === 'OPTIONS') { setCors(res); res.writeHead(204); res.end(); return; }

  // ── Prometheus  /prom/api/v1/query  ─────────────────────────────────────
  if (pathname === '/prom/api/v1/query' || pathname === '/api/v1/query') {
    const q = query.query || '';
    let value = 0;
    if      (q.includes('cpu'))         value = metrics.cpu;
    else if (q.includes('queue'))       value = metrics.queue;
    else if (q.includes('latency'))     value = metrics.latency;
    else if (q.includes('packet_loss')) value = metrics.packetLoss;
    else value = randFloat(0, 10);
    jsonReply(res, {
      status:'success',
      data:{ resultType:'vector', result:[{ metric:{}, value:[Math.floor(Date.now()/1000), String(value)] }] },
    });
    return;
  }

  // ── GET /api/alerts ──────────────────────────────────────────────────────
  if (req.method==='GET' && pathname==='/api/alerts') {
    const limit = parseInt(query.limit||'20', 10);
    const sevCounts = { CRITICAL:0, HIGH:0, MEDIUM:0, LOW:0 };
    alertStore.forEach(a => { if (sevCounts[a.severity]!==undefined) sevCounts[a.severity]++; });
    jsonReply(res, { alerts:alertStore.slice(0,limit), total:alertStore.length, count:alertStore.length, severity_counts:sevCounts });
    return;
  }

  // ── GET /api/alerts/all ──────────────────────────────────────────────────
  if (req.method==='GET' && pathname==='/api/alerts/all') {
    let results = [...alertStore];
    const sevFilter  = (query.severity    ||'').toUpperCase();
    const typeFilter = (query.attack_type ||'').toLowerCase();
    const ipFilter   = (query.src_ip      ||'').toLowerCase();
    if (sevFilter)  results = results.filter(a => a.severity===sevFilter);
    if (typeFilter) results = results.filter(a => a.attack_type.toLowerCase().includes(typeFilter));
    if (ipFilter)   results = results.filter(a => a.src_ip.includes(ipFilter));
    results = results.slice(0, parseInt(query.limit||'500',10));
    const sevCounts = { CRITICAL:0, HIGH:0, MEDIUM:0, LOW:0 };
    results.forEach(a => { if (sevCounts[a.severity]!==undefined) sevCounts[a.severity]++; });
    jsonReply(res, { alerts:results, total:results.length, count:results.length, severity_counts:sevCounts });
    return;
  }

  // ── GET /api/system/status ───────────────────────────────────────────────
  if (req.method==='GET' && pathname==='/api/system/status') {
    const last5 = alertStore.filter(a => Date.now()-new Date(a.timestamp).getTime() < 5*60*1000);
    jsonReply(res, {
      pipeline:'running', zeek:'running', database:'connected', ml_models:'loaded',
      total_alerts:alertStore.length, last_5min:last5.length, recent_alerts:last5.length,
      uptime_secs:Math.floor(process.uptime()), version:'2.1.0-demo',
    });
    return;
  }

  // ── GET /api/system/interfaces ───────────────────────────────────────────
  if (req.method==='GET' && pathname==='/api/system/interfaces') {
    jsonReply(res, { interfaces:[
      { name:'eth0', state:'UP', speed:'1Gbps' }, { name:'ens3',  state:'DOWN', speed:'1Gbps' },
      { name:'wlan0',state:'DOWN',speed:'300Mbps'}, { name:'lo', state:'UP', speed:'loopback' },
    ]});
    return;
  }

  // ── GET /api/system/logs/:id ─────────────────────────────────────────────
  if (req.method==='GET' && pathname.startsWith('/api/system/logs/')) {
    const logId  = pathname.split('/').pop();
    const lines  = parseInt(query.lines||'60', 10);
    const src    = LOG_LINES[logId] || LOG_LINES['pipeline'];
    const output = [];
    for (let i=0; i<lines; i++) output.push(src[i % src.length]);
    jsonReply(res, { log_id:logId, lines:output });
    return;
  }

  // ── POST /api/system/start ───────────────────────────────────────────────
  if (req.method==='POST' && pathname==='/api/system/start') {
    jsonReply(res, { status:'ok', message:'Pipeline started (DEMO MODE)' }); return;
  }

  // ── POST /api/system/stop ────────────────────────────────────────────────
  if (req.method==='POST' && pathname==='/api/system/stop') {
    jsonReply(res, { status:'ok', message:'Pipeline stopped (DEMO MODE)' }); return;
  }

  // ── POST /api/system/train ───────────────────────────────────────────────
  if (req.method==='POST' && pathname==='/api/system/train') {
    jsonReply(res, { status:'ok', message:'Training started (DEMO MODE) — ETA 47s' }); return;
  }

  // ── POST /api/system/reset-firewall ─────────────────────────────────────
  if (req.method==='POST' && pathname==='/api/system/reset-firewall') {
    jsonReply(res, { status:'ok', message:'Firewall rules reset (DEMO MODE)' }); return;
  }

  // ── POST /api/system/clear-db ────────────────────────────────────────────
  if (req.method==='POST' && pathname==='/api/system/clear-db') {
    jsonReply(res, { status:'ok', message:'Database cleared (DEMO MODE — data preserved for demo)' }); return;
  }

  // ── GET /api/soar/playbooks ──────────────────────────────────────────────
  if (req.method==='GET' && pathname==='/api/soar/playbooks') {
    const playbooks = {};
    Object.values(playbookState).forEach(pb => { playbooks[pb.id]=pb.enabled; });
    jsonReply(res, { playbooks }); return;
  }

  // ── POST /api/soar/playbooks/:id ─────────────────────────────────────────
  if (req.method==='POST' && pathname.startsWith('/api/soar/playbooks/')) {
    const pbId = pathname.split('/').pop();
    let body = '';
    req.on('data', d => (body+=d));
    req.on('end', () => {
      try {
        const { enabled } = JSON.parse(body||'{}');
        if (playbookState[pbId]) {
          playbookState[pbId].enabled = !!enabled;
          const playbooks = {};
          Object.values(playbookState).forEach(pb => { playbooks[pb.id]=pb.enabled; });
          jsonReply(res, { status:'ok', playbooks });
        } else {
          jsonReply(res, { status:'error', message:'Playbook not found' }, 404);
        }
      } catch (_) { jsonReply(res, { status:'error', message:'Bad JSON' }, 400); }
    });
    return;
  }

  // ── GET /api/soar/log ────────────────────────────────────────────────────
  if (req.method==='GET' && pathname==='/api/soar/log') {
    jsonReply(res, { log:soarLog.slice(0,50) }); return;
  }

  // ── Static files (React SPA fallback) ────────────────────────────────────
  serveStatic(req.url, res);
});

// WebSocket upgrade on the same server
server.on('upgrade', (req, socket) => {
  if (req.url==='/ws') doWsHandshake(req, socket);
  else socket.destroy();
});

// ─────────────────────────────────────────────────────────────────────────────
// 9.  LIVE ALERT STREAMING  (every 4 seconds)
// ─────────────────────────────────────────────────────────────────────────────

const STREAM_INTERVAL = 4000;

setInterval(() => {
  if (broadcaster.sockets.size === 0) return;

  const roll = Math.random();
  const alert = roll < 0.30 ? makeIoTInboundAlert(0)
              : roll < 0.55 ? makeIoTAlert(0)
              :               makeAlert(0);

  alertStore.unshift(alert);
  if (alertStore.length > 2000) alertStore.pop();

  broadcaster.broadcast(alert);
  console.log(`[WS] #${alert.id} [${alert.severity}] ${alert.attack_type}  ${alert.src_ip} → ${alert.dst_ip}`);

  if (Math.random() < 0.45) {
    soarLog.unshift(makeSoarEntry(0));
    if (soarLog.length > 100) soarLog.pop();
  }
}, STREAM_INTERVAL);

// ─────────────────────────────────────────────────────────────────────────────
// 10.  START
// ─────────────────────────────────────────────────────────────────────────────

const PORT = parseInt(process.env.PORT || '3000', 10);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n╔════════════════════════════════════════════════════╗`);
  console.log(`║     IoT IDS — DEMO MODE  (v2.0 · single-port)     ║`);
  console.log(`╠════════════════════════════════════════════════════╣`);
  console.log(`║                                                    ║`);
  console.log(`║  Dashboard  →  http://localhost:${PORT}             ║`);
  console.log(`║  API        →  http://localhost:${PORT}/api/*       ║`);
  console.log(`║  WebSocket  →  ws://localhost:${PORT}/ws            ║`);
  console.log(`║  Prometheus →  http://localhost:${PORT}/prom/*      ║`);
  console.log(`║                                                    ║`);
  console.log(`║  Seeded alerts : ${String(alertStore.length).padEnd(4)}  New alert every ${STREAM_INTERVAL/1000}s  ║`);
  console.log(`║  Press Ctrl+C to stop                              ║`);
  console.log(`╚════════════════════════════════════════════════════╝\n`);
});
