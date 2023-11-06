#!/bin/bash

# set up azure account credentials
az account set --subscription "$1"
export AD_OUTPUT=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$1")
export ARM_CLIENT_ID="$(echo $AD_OUTPUT | grep appId | cut -d '"' -f4)"
export ARM_CLIENT_SECRET="$(echo $AD_OUTPUT | grep password | cut -d '"' -f12)"
export ARM_SUBSCRIPTION_ID="$1"
export ARM_TENANT_ID="$(echo $AD_OUTPUT | grep tenant | cut -d '"' -f16)"

# execute terraform commands
terraform init
terraform apply -auto-approve

# create file for private key
touch tcKey.pem
chmod 600 tcKey.pem
terraform output tls_private_key > tcKey.pem

# create ansible inventory file with public ip
EVT_TC_IP=$(terraform output public_ip_address | tr -d '"')
cat <<EOF > inventory.yml
webserver:
  hosts:
    vm:
      ansible_host: "$EVT_TC_IP"
      ansible_user: "tcAdmin"
      ansible_ssh_private_key_file: "tcKey.pem"
      ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
EOF

# create server block config file with ip
cat <<EOF > server_block
server {
        listen 443 ssl;
        listen [::]:443 ssl;
        include snippets/self-signed.conf;
        include snippets/ssl-params.conf;

        root /var/www/$EVT_TC_IP/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $EVT_TC_IP;

        location / {
                try_files \$uri \$uri/ =404;
        }
}

server {
    listen 80;
    listen [::]:80;

    server_name $EVT_TC_IP;

    return 302 https://\$server_name\$request_uri;
}
EOF

echo "Waiting for system to boot up..." && sleep 30

# run ansible playbook to configure webserver
ansible-playbook -i inventory.yml playbook.yml
echo "Access webserver in a browser at https://$EVT_TC_IP"