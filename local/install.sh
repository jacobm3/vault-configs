curl --silent --remote-name https://releases.hashicorp.com/vault/1.3.2+ent/vault_1.3.2+ent_linux_amd64.zip
unzip vault_1.3.2+ent_linux_amd64.zip

sudo chown root:root vault
sudo mv vault /usr/local/bin/
vault --version

vault -autocomplete-install
complete -C /usr/local/bin/vault vault

sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

sudo useradd --system --home /etc/vault.d --shell /bin/false vault

sudo touch /etc/systemd/system/vault.service

cat >> /tmp/vault.service <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

mv /tmp/vault.service /etc/systemd/system/vault.service

sudo mkdir --parents /etc/vault.d
sudo mkdir --parents /etc/vault.d/plugins
sudo touch /etc/vault.d/vault.hcl
sudo chown --recursive vault:vault /etc/vault.d
sudo chmod 640 /etc/vault.d/vault.hcl

cat >> /tmp/vault.hcl <<EOF
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/ssl/vault-cert.crt"
  tls_key_file  = "/vault/ssl/vault-key.pem"
}

storage "file" {
  path = "/vault/data"
}

ui = "true"
api_addr = "https://vault.jacobm.azure.hashidemos.io:8200/"
plugin_directory = "/etc/vault.d/plugins"
EOF

sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault


