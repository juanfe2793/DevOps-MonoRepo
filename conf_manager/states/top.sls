---
base:
  '*':
    - users

  'roles:jenkins':
    - match: grain
    - jenkins
    - nginx.jenkins
    - docker
    - packer
    - python
  
