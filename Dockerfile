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
        curl \
        sudo \
        git \
        jq \
        iputils-ping \
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
    && sudo chmod -R g+w /home/github

RUN curl -v -skL -o /tmp/helm.tar.gz https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz && \
        tar -C /tmp -xzf /tmp/helm.tar.gz && \
        sudo mv /tmp/linux-amd64/helm /usr/local/bin && \
        sudo chmod -R 775 /usr/local/bin/helm && \
        rm -rf /tmp/helm.tar.gz && \
        rm -rf /tmp/linux-amd64

COPY --chown=github:root entrypoint.sh runsvc.sh ./
RUN sudo chmod ug+x ./entrypoint.sh ./runsvc.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]

