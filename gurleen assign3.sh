#!/bin/bash

# gurleen kaur
# 200522530
# to configure the servers remotly
# we have their ip addresses.
server1_mgmt_ip="172.16.1.10"
server2_mgmt_ip="172.16.1.11"
 

# now using these ip we can use ssh to control the servers
# remotely.

# we start from server one.
# we will write commands one by one to change the configurations.
# we are giving gaps to differentiate different commands.
ssh remoteadmin@$server1_mgmt_ip << EOF
 
    hostnamectl set-hostname loghost

   
    ip addr add 192.168.1.3/24 dev eth0

   
    echo '192.168.1.4 webhost' | tee -a /etc/hosts

   
    dpkg -l | grep -E '^ii' | grep -q ufw || apt-get install -y ufw
    ufw allow from 172.16.1.0/24 to any port 514/udp

   
    sed -i '/imudp/s/^#//g' /etc/rsyslog.conf
    sed -i '/UDPServerRun/s/^#//g' /etc/rsyslog.conf
    systemctl restart rsyslog
EOF

# now we have successfully done the first server.
# we will start next server just like this.


# these also have almost same commands.
# but we have to add the ip on lan 4
# thats why 192.168.1.4
# also loghost will come with 192.168.1.3



# we will also install apache in this.
# then we will also add the last line in rsyslog before restarting it
# the line is *.* @loghost
ssh remoteadmin@$server2_mgmt_ip << EOF

    hostnamectl set-hostname webhost

   
    ip addr add 192.168.1.4/24 dev eth0

    
    echo '192.168.1.3 loghost' | tee -a /etc/hosts

   
    dpkg -l | grep -E '^ii' | grep -q ufw || apt-get install -y ufw
    ufw allow 80/tcp

    
    apt-get install -y apache2

    
    echo '*.* @loghost' | tee -a /etc/rsyslog.conf
    systemctl restart rsyslog
EOF



# now we have completed both servers.
# we will update the given information about new hostnames and ip addresses.
# we will do this inside the /etc/hosts file.
 

echo "192.168.1.3 loghost" | sudo tee -a /etc/hosts
echo "192.168.1.4 webhost" | sudo tee -a /etc/hosts

# now after doing all the commands, 
# our last  part is Verification.       

# first we will Verify Apache configuration
curl -s http://webhost | grep -q "Apache2 Ubuntu Default Page"
# we have to give proper messaging to the user.
if [ $? -eq 0 ]; then
    echo "Apache configured successfully."
else
    echo "Apache configuration is not successful."
fi


# last verification is of the syslog

ssh remoteadmin@loghost "grep webhost /var/log/syslog" | grep -q "webhost"
if [ $? -eq 0 ]; then
    echo "Syslog configured successfully."
else
    echo "Syslog configuration is not successful."
fi

# done!!
