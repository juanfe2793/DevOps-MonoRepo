#!/bin/bash
set -euf -o pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1
# Init migration files
sudo python3 /home/ec2-user/python-devops-app/manage.py db init
sudo python3 /home/ec2-user/python-devops-app/manage.py db migrate -m "DB init"
sudo python3 /home/ec2-user/python-devops-app/manage.py db upgrade
# Init application
sudo python3 /home/ec2-user/python-devops-app/manage.py runserver -h '0.0.0.0'