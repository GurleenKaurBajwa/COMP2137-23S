#!/bin/bash
if [ "$(hostname)" != "autosrv" ]; then
        local HOSTNAME="autosrv"
        hostnamectl set-hostname $HOSTNAME
fi  
# to check and set network configuration

local interface="ens34"
local ip_address="192.168.16.21/24"
local gateway="192.168.16.1"

    # Check if interface exists
if ! ip link show $interface &> /dev/null; then
    echo "Interface $interface not found."
fi

    # Check if IP address is set
if ! ip addr show $interface | grep -q "$ip_address"; then
    echo "Setting IP address $ip_address on $interface..."
    ip addr add $ip_address dev $interface
fi

    # Check if default gateway is set
if ! ip route | grep -q "default via $gateway"; then
    echo "Setting default gateway $gateway via $interface..."
    ip route add default via $gateway dev $interface
fi
echo "Network Settings are up to date"
# to check and set software configuration
apt-get update
apt-get install -y openssh-server apache2 squid
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
echo "Software configurations are up to date"
systemctl restart sshd
# to check and set firewall rules
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3128/tcp
echo "All firewall rules are set up"
# Function to set up users and their SSH keys
setup_users() {
    local users=("dennis" "aubrey" "captain" "nibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    local dennis_pub_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

    for user in "${users[@]}"; do
        # Check if the user already exists
        if id "$user" &>/dev/null; then
            echo "User $user already exists."
        else
            # Create the user
            useradd -m -s /bin/bash "$user"
            echo "$user user created."
        fi

        # Create .ssh directory and set permissions
        mkdir -p "/home/$user/.ssh"
        chown -R "$user:$user" "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"

        # Check if the authorized_keys file exists
        if [[ ! -f "/home/$user/.ssh/authorized_keys" ]]; then
            touch "/home/$user/.ssh/authorized_keys"
        fi

        # Add SSH keys to the authorized_keys file
        if ! grep -q "$dennis_pub_key" "/home/$user/.ssh/authorized_keys"; then
            echo "$dennis_pub_key" >>"/home/$user/.ssh/authorized_keys"
            echo "Added Dennis' public key to $user's authorized_keys file."
        fi

        # Set proper permissions for authorized_keys
        chmod 600 "/home/$user/.ssh/authorized_keys"
    done

    # Grant sudo access to dennis
    usermod -aG sudo dennis
}

setup_users

echo "Setup complete."
