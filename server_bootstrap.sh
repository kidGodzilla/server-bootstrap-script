#!/bin/bash
# This script will install ledokku on your server
# You need to already have dokku installed in order to be able to run it
set -e

check_root() {
if [ "$USER" != "root" ]; then
      echo "Permission Denied"
      echo "Can only be run by root"
      exit
fi
}

apt-get-update() {
	sudo apt-get update
}

disable-password-authentication() {
	# Disable password authentication
	sudo grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
	sudo grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
	/etc/init.d/ssh reload
}

# Get Dokku
install-dokku() {
	wget https://raw.githubusercontent.com/dokku/dokku/v0.21.4/bootstrap.sh
	sudo DOKKU_TAG=v0.21.4 bash ./bootstrap.sh
}

keys-file() {
	mkdir -p ~/.ssh
	touch ~/.ssh/authorized_keys
}

install-firewall() {
	apt-get install ufw
	ufw enable && sudo ufw allow ssh && sudo ufw allow www && sudo ufw status
}


# Check that dokku is installed on the server
ensure-dokku() {
  if ! command -v dokku &> /dev/null
  then
      echo "dokku is not installed"
      exit
  fi
}

# Check if dokku redis plugin is intalled and otherwise install it
install-redis() {
  if sudo dokku plugin:installed redis; then
    echo "=> Redis plugin already installed skipping"
  else
    echo "=> Installing redis plugin"
    sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
  fi
}

# Check if dokku postgres plugin is intalled and otherwise install it
install-postgres() {
  if sudo dokku plugin:installed postgres; then
    echo "=> Postgres plugin already installed skipping"
  else
    echo "=> Installing postgres plugin"
    sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
  fi
}

# Check if dokku MySQL plugin is intalled and otherwise install it
install-mysql() {
  if sudo dokku plugin:installed mysql; then
    echo "=> Postgres plugin already installed skipping"
  else
    echo "=> Installing mysql plugin"
    sudo dokku plugin:install https://github.com/dokku/dokku-mysql.git mysql
  fi
}

# Check if dokku mongo plugin is intalled and otherwise install it
install-mongo() {
  if sudo dokku plugin:installed mongo; then
    echo "=> Postgres plugin already installed skipping"
  else
    echo "=> Installing mongo plugin"
    sudo dokku plugin:install https://github.com/dokku/dokku-mongo.git mongo
  fi
}

install-letsencrypt() {
	sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
}

install-limited-users() {
	sudo dokku plugin:install https://github.com/kidGodzilla/dokku-limited-users.git
}

main() {
  check_root

  # First we get the user ip so we can use it in the text we print later
  DOKKU_SSH_HOST=$(curl ifconfig.co)

  # Basics
  apt-get-update
  install-firewall
  install-dokku
  keys-file

  # Hardening
  disable-password-authentication

  # Ensure dokku was installed
  ensure-dokku

  # dokku databases & plugins
  install-redis
  install-postgres
  install-mysql
  install-mongo
  install-letsencrypt
  install-limited-users

}

main