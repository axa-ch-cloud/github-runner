FROM debian:buster-slim

ENV GITHUB_PAT ""
ENV GITHUB_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""
ENV ADDITIONAL_PACKAGES ""

RUN apt-get update \
    && apt -o Debug::Acquire::http=true -o Debug::Acquire::https=true install -y \
        curl \
        sudo \
        git \
        jq \
        iputils-ping \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github
WORKDIR /home/github

COPY --chown=github:github installdependencies.sh entrypoint.sh runsvc.sh ./

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && mv -f installdependencies.sh bin/installdependencies.sh \
    && chmod +x bin/installdependencies.sh \
    && cat bin/installdependencies.sh \
    && sudo --preserve-env=HTTP_PROXY --preserve-env=HTTPS_PROXY --preserve-env=http_proxy --preserve-env=https_proxy ./bin/installdependencies.sh 



RUN sudo chmod u+x ./entrypoint.sh ./runsvc.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]
