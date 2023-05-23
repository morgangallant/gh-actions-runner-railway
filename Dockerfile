# A simple Dockerfile for hosting a Linux-based GH actions runner.
FROM debian:stable-slim

# Requires the following variables.
ARG GITHUB_TOKEN
ARG GITHUB_OWNER

# Dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates tar gzip sudo gnupg
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Can't run as root, so create a user and switch to it.
# Make the user a sudoer.
RUN useradd -m actions
RUN usermod -aG sudo actions
RUN echo "actions ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER actions
WORKDIR /home/actions

# Download and install the runner.
RUN curl -o actions-runner-linux-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-x64-2.304.0.tar.gz
RUN tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz
RUN sudo ./bin/installdependencies.sh
RUN ./config.sh --url https://github.com/${GITHUB_OWNER} --token ${GITHUB_TOKEN}
ENTRYPOINT ["./run.sh"]