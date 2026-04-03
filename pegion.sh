#!/bin/bash
# DevOps Monitoring Setup: Prometheus, Grafana, Node Exporter

# --- VARIABLES (Update these for future versions) ---
PROM_VER="2.43.0"
NODE_EXP_VER="1.5.0"
PROM_USER="prometheus"
NODE_USER="node_exporter"

# --- 1. PROMETHEUS INSTALLATION ---
echo "Installing Prometheus v$PROM_VER..."

# Create users and directories first
sudo useradd -rs /bin/false $PROM_USER
sudo mkdir -p /etc/prometheus /var/lib/prometheus

# Download and extract
wget -q https://github.com/prometheus/prometheus/releases/download/v$PROM_VER/prometheus-$PROM_VER.linux-amd64.tar.gz
tar -xf prometheus-$PROM_VER.linux-amd64.tar.gz

# Move binaries and libraries
sudo mv prometheus-$PROM_VER.linux-amd64/prometheus prometheus-$PROM_VER.linux-amd64/promtool /usr/local/bin/
sudo mv prometheus-$PROM_VER.linux-amd64/console_libraries /etc/prometheus/
sudo mv prometheus-$PROM_VER.linux-amd64/consoles /etc/prometheus/

# Cleanup
rm -rf prometheus-$PROM_VER.linux-amd64*

# Configuration File (Using your specific targets)
sudo tee /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus_metrics'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter_metrics'
    static_configs:
      - targets: ['localhost:9100', 'worker-1:9100', 'worker-2:9100']
EOF

# Permissions
sudo chown -R $PROM_USER:$PROM_USER /etc/prometheus /var/lib/prometheus

# Systemd Service
sudo tee /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$PROM_USER
Group=$PROM_USER
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file /etc/prometheus/prometheus.yml \\
    --storage.tsdb.path /var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

# --- 2. GRAFANA INSTALLATION (Official Repo) ---
echo "Installing Grafana..."

sudo rpm --import https://rpm.grafana.com/gpg.key
sudo tee /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo yum install grafana -y
sudo systemctl enable --now grafana-server

# --- 3. NODE EXPORTER INSTALLATION ---
echo "Installing Node Exporter v$NODE_EXP_VER..."

sudo useradd -rs /bin/false $NODE_USER
wget -q https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXP_VER/node_exporter-$NODE_EXP_VER.linux-amd64.tar.gz
tar -xf node_exporter-$NODE_EXP_VER.linux-amd64.tar.gz
sudo mv node_exporter-$NODE_EXP_VER.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-$NODE_EXP_VER.linux-amd64*

# Systemd Service
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$NODE_USER
Group=$NODE_USER
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

echo "Setup Complete! Check statuses below:"
sudo systemctl is-active prometheus grafana-server node_exporter
