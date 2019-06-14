# -*- coding: utf-8 -*-
# vim: ft=sls

Install Docker repo dependencies:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates
      - curl

Setup Docker apt repository:
  pkgrepo.managed:
    - name: deb https://download.docker.com/linux/ubuntu stretch edge
    - file: /etc/apt/sources.list.d/docker.list
    - require:
      - pkg: Install Docker repo dependencies
    - key_url: https://download.docker.com/linux/ubuntu/gpg

Install Docker and bindings:
  pkg.installed:
    - pkgs:
      - docker-ce
      - python-docker
    - require:
      - pkgrepo: Setup Docker apt repository
    - reload_modules: True

Run Docker:
  service.running:
    - name: docker
    - require:
      - pkg: Install Docker and bindings

mariadb:
  docker_container.running:
    - name: mariadb
    - image: mariadb:10
    - restart_policy: always
    - environment:
      - MYSQL_RANDOM_ROOT_PASSWORD: yes
      - MYSQL_DATABASE: wordpress
      - MYSQL_USER: wordpress
      - MYSQL_PASSWORD: wordpress
    - require:
      - service: Run Docker

wordpress:
  docker_container.running:
    - name: wordpress
    - image: wordpress:4
    - port_bindings:
      - 80:80
    - links:
      - mariadb:db
    - restart_policy: always
    - environment:
      - WORDPRESS_DB_HOST: db:3306
      - WORDPRESS_DB_USER: wordpress
      - WORDPRESS_DB_PASSWORD: wordpress
    - require:
      - docker_container: mariadb
      #- service: Run Docker
      - cmd: Run Docker

unifi:
  docker_container.running:
    - name: unifi
    - restart_policy: always
    - image: jacobalberty/unifi:5.9
    - binds:
      - unifi_config:/unifi/data:rw
      - unifi_logs:/unifi/log:rw
    - port_bindings:
      - 8080:8080
      - 8443:8443
      - 8843:8843
      - 8880:8880
      - 3478:3478/udp
      - 6789:6789
      - 10001:10001/udp
    - require:
      - service: Run Docker

unifi_config:
  docker_volume.present:
    - name: unifi_config
    - driver: local

unifi_logs:
  docker_volume.present:
    - name: unifi_logs
    - driver: local