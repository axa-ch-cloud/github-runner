FROM debian:buster-slim

ENV GITHUB_PAT ""
ENV GITHUB_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""
ENV ADDITIONAL_PACKAGES ""

ADD https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz /opt/oc/release.tar.gz

RUN tar --strip-components=1 -xzvf  /opt/oc/release.tar.gz -C /opt/oc/ && \
    mv /opt/oc/oc /usr/bin/ && \
    rm -rf /opt/oc

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

COPY [ "certs/AXA-Enterprise-Root-CA.crt", "certs/AXA-Proxy-ROOT-CA.crt", "/usr/local/share/ca-certificates/" ]
RUN update-ca-certificates

USER github
WORKDIR /home/github

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo --preserve-env=HTTP_PROXY --preserve-env=HTTPS_PROXY --preserve-env=http_proxy --preserve-env=https_proxy ./bin/installdependencies.sh \
    && sudo chgrp -R 0 /home/github \
    && sudo chmod -R g+w /home/github

RUN curl -v -skL -o /tmp/helm.tar.gz https://get.helm.sh/helm-v3.10.0-linux-amd64.tar.gz && \
        tar -C /tmp -xzf /tmp/helm.tar.gz && \
        sudo mv /tmp/linux-amd64/helm /usr/local/bin && \
        sudo chmod -R 775 /usr/local/bin/helm && \
        rm -rf /tmp/helm.tar.gz && \
        rm -rf /tmp/linux-amd64 && \
	sudo mkdir /.kube && \
        sudo chgrp -R 0 /.kube && \
	sudo chmod -R g+w /.kube

COPY --chown=github:root entrypoint.sh runsvc.sh ./
RUN sudo chmod ug+x ./entrypoint.sh ./runsvc.sh

COPY --chown=github:root contrib/bin/* /usr/local/bin/
COPY --chown=github:root contrib/tmp/* /tmp/

RUN sudo chmod a+x /usr/local/bin/age && \
    sudo mkdir -p "/.local/share/helm/plugins" && \
    sudo tar -C "/.local/share/helm/plugins" -xzf /tmp/helm-secrets.tar.gz && \
    curl -v -skL -o /tmp/sops https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 && \
    sudo mv /tmp/sops /usr/local/bin/ && \
    sudo chmod -R 775 /usr/local/bin/sops && \
    rm -rf /tmp/sops && \
    rm /tmp/helm-secrets.tar.gz

ENTRYPOINT ["/home/github/entrypoint.sh"]

