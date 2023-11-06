FROM ubuntu:22.04
COPY ./src /app
RUN apt-get update && apt-get install -y sudo sed wget curl lsb-release gpg
RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN HASHICORP_FINGERPRINT=$(gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint | sed -n 4p | sed -e 's/^[ \t]*//')
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
RUN sudo apt update
RUN apt install -y terraform
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-venv \
    && python3 -m pip install pipx \
    && python3 -m pipx ensurepath \
    && pipx install --include-deps ansible