#!/bin/bash

usage() {
  echo "Usage: $0 <user> <remote_host> <new_user> <public_key_path>"
  echo ""
  echo "  user             Existing user with sudo access on the remote host"
  echo "  remote_host      IP address or hostname of the remote server"
  echo "  new_user         Username to create on the remote host"
  echo "  public_key_path  Path to your local public key (e.g. ~/.ssh/id_rsa.pub)"
  echo ""
  echo "Example:"
  echo "  $0 admin 192.168.1.10 newuser ~/.ssh/id_rsa.pub"
  exit 1
}

# Check all arguments are provided
if [ "$#" -ne 4 ]; then
  usage
fi

user=$1
remote_host=$2
new_user=$3
public_key_path=$4

# Check the public key file exists
if [ ! -f "$public_key_path" ]; then
  echo "Error: Public key file '$public_key_path' not found."
  exit 1
fi

public_key=$(cat "$public_key_path")

ssh -t "$user@$remote_host" "
  sudo adduser --gecos '' $new_user &&
  sudo usermod -aG sudo $new_user &&
  sudo mkdir -p /home/$new_user/.ssh &&
  sudo chmod 700 /home/$new_user/.ssh &&
  echo '$public_key' | sudo tee /home/$new_user/.ssh/authorized_keys &&
  sudo chmod 600 /home/$new_user/.ssh/authorized_keys &&
  sudo chown -R $new_user:$new_user /home/$new_user/.ssh
"

if [ $? -eq 0 ]; then
  echo "User '$new_user' created successfully on $remote_host."
  echo "You can now connect with: ssh $new_user@$remote_host"
else
  echo "Something went wrong. Check the output above."
  exit 1
fi
