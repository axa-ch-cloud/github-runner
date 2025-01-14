#!/bin/sh

if [ -n "${ADDITIONAL_PACKAGES}" ]; then
    TO_BE_INSTALLED=$(echo ${ADDITIONAL_PACKAGES} | tr "," " " )
    echo "Installing additional packages: ${TO_BE_INSTALLED}"
    sudo apt-get update && sudo apt-get install -y ${TO_BE_INSTALLED} && sudo apt-get clean
fi

registration_url="https://github.com/${GITHUB_OWNER}"
token_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"

if [ -n "${GITHUB_TOKEN}" ]; then
    echo "Using given GITHUB_TOKEN"

    if [ -z "${GITHUB_REPOSITORY}" ]; then
        echo "When using GITHUB_TOKEN, the GITHUB_REPOSITORY must be set"
        return
    fi

    registration_url="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}"
    export RUNNER_TOKEN=$GITHUB_TOKEN

else
    if [ -n "${GITHUB_REPOSITORY}" ]; then
        token_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
        registration_url="${registration_url}/${GITHUB_REPOSITORY}"
    fi

    echo "Requesting token at '${token_url}'"
    whoami
    echo $GITHUB_PAT
    payload=$(curl -vX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url})
    echo $payload
    echo $(echo $payload | jq .token --raw-output)
    export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)
    echo $RUNNER_TOKEN

fi

if [ -z "${RUNNER_NAME}" ]; then
    RUNNER_NAME=$(hostname)
fi

echo '#########################'
echo $RUNNER_NAME
echo $RUNNER_TOKEN
echo $registration_url
echo $RUNNER_WORKDIR
echo $RUNNER_LABELS
echo $HTTPS_PROXY
echo $HTTP_PROXY
echo $https_proxy
echo $http_proxy
echo $no_proxy

echo '#########################'

./config.sh \
    --name "${RUNNER_NAME}" \
    --token "${RUNNER_TOKEN}" \
    --url "${registration_url}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

echo 'Config finished'

remove() {
    if [ -n "${GITHUB_TOKEN}" ]; then
        export REMOVE_TOKEN=$GITHUB_TOKEN
    else
        payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url%/registration-token}/remove-token)
        export REMOVE_TOKEN=$(echo $payload | jq .token --raw-output)
    fi

    ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
}

trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

echo 'Running runsvc.sh'

./runsvc.sh "$*" &

wait $!

