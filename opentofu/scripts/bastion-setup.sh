#!/bin/bash

LOGS_PARENT_DIR="/var/log"
TOFU_LOG="${LOGS_PARENT_DIR}/tofu.log"
ANSIBLE_LOG="${LOGS_PARENT_DIR}/ansible.log"
WORKING_DIR="/opt/starfleet"
GIT_REPO="https://github.com/SurgeVortex/starfleet-home-automation.git"
TOFU_RUN="${WORKING_DIR}/run-tofu.sh auto-approve"
ANSIBLE_RUN="${WORKING_DIR}/run-ansible.sh"
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

if ! command_exists az
then
    echo "az not found, installing now."
    sudo apt-get update
    sudo pip install azure-cli
fi

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

# Ensure log files are created and owned by the current user
if [ ! -f "$TOFU_LOG" ] || [ "$(stat -c %U "$TOFU_LOG")" != "$USER" ]
then
    echo "Creating log file: $TOFU_LOG"
    sudo touch "$TOFU_LOG"
    sudo chown $USER:$USER "$TOFU_LOG"
fi

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

# Add cron job if not already present
if ! crontab -l | grep -q "$TOFU_RUN >> $TOFU_LOG"
then
    echo "Adding cron job for OpenTOFU"
    (crontab -l 2>/dev/null; echo "*/5 * * * * cd $WORKING_DIR && git fetch origin && git reset --hard origin/main && timeout ${TIMEOUT} $TOFU_RUN >> $TOFU_LOG 2>&1") | crontab -
fi

if ! crontab -l | grep -q "$ANSIBLE_RUN >> $ANSIBLE_LOG"
then
    echo "Adding cron job for Ansible"
    (crontab -l 2>/dev/null; echo "*/10 * * * * cd $WORKING_DIR && git fetch origin && git reset --hard origin/main && timeout ${TIMEOUT} $ANSIBLE_RUN >> $ANSIBLE_LOG 2>&1") | crontab -
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

$ANSIBLE_LOG {
    rotate $ROTATE_COUNT
    size $ROTATE_SIZE
    compress
    missingok
    notifempty
    copytruncate
}
EOL
fi
