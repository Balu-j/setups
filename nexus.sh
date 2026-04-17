#!/bin/bash
sudo yum update -y
sudo yum install wget java-11-amazon-corretto-headless -y

sudo mkdir -p /app && cd /app
sudo wget https://download.sonatype.com/nexus/3/nexus-3.75.1-01-unix.tar.gz
sudo tar -xvzf nexus-3.75.1-01-unix.tar.gz
sudo mv nexus-3.75.1-01 nexus

# CRITICAL: Fix RAM for t2.micro (1GB RAM)
sudo sed -i 's/-Xms2703m/-Xms512m/g' /app/nexus/bin/nexus.vmoptions
sudo sed -i 's/-Xmx2703m/-Xmx512m/g' /app/nexus/bin/nexus.vmoptions
sudo sed -i 's/-XX:MaxDirectMemorySize=2703m/-XX:MaxDirectMemorySize=512m/g' /app/nexus/bin/nexus.vmoptions

sudo adduser nexus
sudo chown -R nexus:nexus /app/nexus /app/sonatype-work
sudo echo 'run_as_user="nexus"' > /app/nexus/bin/nexus.rc

sudo tee /etc/systemd/system/nexus.service > /dev/null << EOL
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus
