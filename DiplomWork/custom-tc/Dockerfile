# Dockerfile
FROM jetbrains/teamcity-agent:2022.10.1-linux-sudo

USER root

# Установка kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# копирование terraform
COPY terraform /usr/local/bin/
