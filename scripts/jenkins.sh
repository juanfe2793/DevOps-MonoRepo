#!/bin/bash
set -euf -o pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1
## Install Git 
# (required for access via IAM roles)
sudo yum -y install git
## Clone Saltstack repository 
sudo git clone https://github.com/juanfe2793/Config-Manager.git /srv/ConfManager; sudo chmod 700 /srv/ConfManager
## Install SaltStack
sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
sudo yum clean expire-cache; sudo yum -y install salt-minion; chkconfig salt-minion off
# Put custom minion config in place (for enabling masterless mode)
sudo cp -r /srv/ConfManager/minion.d /etc/salt/
sudo echo -e 'grains:\n roles:\n  - jenkins' > /etc/salt/minion.d/grains.conf
## Trigger a full Salt run
sudo salt-call state.apply