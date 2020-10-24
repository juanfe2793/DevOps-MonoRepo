---
include:
  - nginx 

python:
  pkg.installed:
    - pkgs:
      - python3

install_flask:
  cmd.run:
    - name: "sudo pip3 install flask flask-migrate flask-script"
    - require:
      - pkg: python