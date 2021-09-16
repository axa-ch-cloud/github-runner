FROM debian:buster-slim

ENV GITHUB_PAT ""
ENV GITHUB_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""
ENV ADDITIONAL_PACKAGES ""

RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        curl \
        sudo \
        git \
        jq \
        iputils-ping \
    &&  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo \
         "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
         $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "github ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github
WORKDIR /home/github

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo --preserve-env=HTTP_PROXY --preserve-env=HTTPS_PROXY --preserve-env=http_proxy --preserve-env=https_proxy ./bin/installdependencies.sh \
    && sudo chgrp -R 0 /home/github \
    && sudo chmod -R g+w /home/github \
    && usermod -a -G docker 1001860000
    
COPY --chown=github:root entrypoint.sh runsvc.sh ./
RUN sudo chmod ug+x ./entrypoint.sh ./runsvc.sh

USER 1001860000

ENTRYPOINT ["/home/github/entrypoint.sh"]

