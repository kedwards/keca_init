#!/usr/bin/env bash

[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:$PATH"
[[ ":$PATH:" != *":$HOME/.pyenv/bin:"* ]] && PATH="$HOME/.pyenv/bin:$PATH"

export PATH

SYSINIT_PATH=$HOME/sysinit
RELEASE=$(cat /etc/os-release | grep '^ID=' | awk '{ split($0, a, "="); print a[2]}')
CODENAME=$(lsb_release -cs)

if [ ! $(which git) ]; then
  sudo apt-get install -y git
fi

[ ! -d $HOME/.pyenv ] && curl https://pyenv.run | bash

if ! grep -Fxq "# sysinit: load custom bash settings" $HOME/.bashrc; then
  cat << EOF >> $HOME/.bashrc
# sysinit: load custom bash settings
if [ -f $HOME/.bash_profile ]; then
  . $HOME/.bash_profile
fi
EOF
fi

eval "$(pyenv init -)"

pyenv virtualenv sysinit && pyenv activate sysinit

pip install -r "${SYSINIT_PATH}/requirements.txt"
ansible-galaxy install -r "${SYSINIT_PATH}/requirements.yml"

[ -d "${SYSINIT_PATH}" ] || git clone -b main --single-branch https://github.com/kedwards/sysinit.git "$SYSINIT_PATH"
cd "${SYSINIT_PATH}"

[ -f /etc/apt/keyrings/docker.gpg ] || curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y

ansible-playbook playbook.yml -K --ask-vault-pass --tags core
