#!/bin/bash

LOGS_PARENT_DIR="/var/log"
TOFU_LOG="${LOGS_PARENT_DIR}/tofu.log"
ANSIBLE_LOG="${LOGS_PARENT_DIR}/ansible.log"
WORKING_DIR="/opt/starfleet"
GIT_REPO="https://github.com/SurgeVortex/starfleet-home-automation.git"
TOFU_RUN="${WORKING_DIR}/run-tofu.sh auto-approve"
TIMEOUT=30m
LOG_ROTATE_CONF="/etc/logrotate.d/starfleet"
ROTATE_COUNT=5
ROTATE_SIZE="10M"

# Function to check if a command is already installed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
if ! command_exists python3
then
    echo "Python3 not found, installing now."
    sudo apt-get update
    sudo NEEDRESTART_MODE=a apt-get install -y python3
fi

if ! command_exists pip3
then
    echo "pip3 not found, installing now."
    sudo apt-get update
    sudo NEEDRESTART_MODE=a apt-get install -y python3-pip
fi

if ! command_exists jq
then
    echo "jq not found, installing now."
    sudo apt-get update
    sudo NEEDRESTART_MODE=a apt-get install -y jq
fi

# Ensure azure-cli is installed
if ! command_exists az
then
    echo "az not found, installing now."
    sudo apt-get update
    sudo pip install azure-cli
fi

# Ensure curl is installed
if ! command_exists curl
then
    echo "curl not found, installing now."
    sudo apt-get update
    sudo NEEDRESTART_MODE=a apt-get install -y curl
fi

# Download and install OpenTOFU
if ! command_exists tofu
then
    echo "OpenTOFU not found, installing now."
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb
    rm -f install-opentofu.sh
fi

# Install Ansible using pipx
if ! command_exists ansible
then
    echo "Ansible not found, installing now."
    sudo pip install ansible argcomplete
    (
        sudo activate-global-python-argcomplete3
        activate-global-python-argcomplete3
    ) | bash
fi

# Ensure logrotate is installed
if ! command_exists logrotate
then
    echo "logrotate not found, installing now."
    sudo apt-get update
    sudo NEEDRESTART_MODE=a apt-get install -y logrotate
fi

# Ensure git is installed
if ! command_exists git
then
    echo "git not found, installing now."
    sudo apt-get update
    apt-get install -y git
fi

# Ensure kubectl is installed
if ! command_exists kubectl
then
    echo "helm not found, installing now."
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
    sudo apt-get update
    sudo apt-get install -y kubectl
fi

# # Ensure helm is installed
# if ! command_exists helm
# then
#     echo "helm not found, installing now."
#     sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
#     curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
#     sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
#     echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
#     sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
#     sudo apt-get update
#     sudo apt-get install -y kubectl
# fi

# Ensure log files are created and owned by the current user
if [ ! -f "$TOFU_LOG" ] || [ "$(stat -c %U "$TOFU_LOG")" != "$USER" ]
then
    echo "Creating log file: $TOFU_LOG"
    sudo touch "$TOFU_LOG"
    sudo chown $USER:$USER "$TOFU_LOG"
fi

# Ensure log files are created and owned by the current user
if [ ! -f "$ANSIBLE_LOG" ] || [ "$(stat -c %U "$ANSIBLE_LOG")" != "$USER" ]
then
    echo "Creating log file: $ANSIBLE_LOG"
    sudo touch "$ANSIBLE_LOG"
    sudo chown $USER:$USER "$ANSIBLE_LOG"
fi

# Create the working directory if it doesn't exist
if [ ! -d "$WORKING_DIR" ]
then
    echo "Creating working directory: $WORKING_DIR"
    sudo mkdir -p "$WORKING_DIR"
    sudo chown $USER:$USER "$WORKING_DIR"
fi

# Check if the working directory is empty
if [ -z "$(ls -A $WORKING_DIR)" ]
then
    echo "Cloning git repository: $GIT_REPO into $WORKING_DIR"
    git clone "$GIT_REPO" "$WORKING_DIR"
fi

# Create a script to run the OpenTOFU command
CRON_SCRIPT="/usr/local/bin/run-cron.sh"

if [ ! -f "$CRON_SCRIPT" ]
then
    echo "Creating cron script: $CRON_SCRIPT"
    sudo tee "$CRON_SCRIPT" > /dev/null <<EOL
#!/bin/bash
source ~/.profile
sudo -u $USER bash <<EOF
cd $WORKING_DIR
git fetch origin
git reset --hard origin/main
timeout ${TIMEOUT} $TOFU_RUN >> $TOFU_LOG 2>&1
EOF
EOL
    sudo chmod +x "$CRON_SCRIPT"
fi

# Update cron job to use the new script
if ! crontab -l | grep -q "$CRON_SCRIPT"
then
    echo "Updating cron job to use the new script"
    (crontab -l 2>/dev/null; echo "*/5 * * * * $CRON_SCRIPT") | crontab -
fi

# Create logrotate configuration if it doesn't exist
if [ ! -f "$LOG_ROTATE_CONF" ]
then
    echo "Creating logrotate configuration: $LOG_ROTATE_CONF"
    sudo tee "$LOG_ROTATE_CONF" > /dev/null <<EOL
$TOFU_LOG {
    rotate $ROTATE_COUNT
    size $ROTATE_SIZE
    compress
    missingok
    notifempty
    copytruncate
}
EOL
fi
