terraform init
terraform apply -auto-approve
touch tcKey.pem
chmod 600 tcKey.pem
terraform output tls_private_key > tcKey.pem
EVT_TC_IP="$(terraform output public_ip_address)"
cat <<EOF > inventory.yml
webserver:
  hosts:
    vm:
      ansible_host: $EVT_TC_IP
EOF
ansible-playbook -i inventory.yml playbook.yml
echo "Access webserver in a browser at $http://EVT_TC_IP"