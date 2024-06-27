#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

# Überprüfen, ob curl installiert ist, und ggf. installieren
curl --version > /dev/null
if [[ $? -ne 0 ]]; then
  echo "${yellow}Curl is not installed. Installing curl...${nc}"
  apt -y install curl
fi

clear

# Funktion zur Anzeige von Statusnachrichten
status(){
  clear
  echo -e "${green}$@...${nc}"
  sleep 1
}

# Einbindung der BashSelect-Funktionalität
source <(curl -s https://raw.githubusercontent.com/DeinGithubUsername/DeinRepo/main/BashSelect.sh)

# Auswahl der Aktionen
export OPTIONS=("install FiveM" "update FiveM" "do nothing")

status "Choose an action:"
bashSelect

case $? in
     0 )
        action="install";;
     1 )
        action="update";;
     2 )
        exit 0;;
esac

# Auswahl der Runtime-Version
status "Select a runtime version:"
readarray -t VERSIONS <<< $(curl -s https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ | egrep -m 3 -o '[0-9].*/fx.tar.xz')

latest_recommended=$(echo "${VERSIONS[0]}" | cut -c 1-4)
latest=$(echo "${VERSIONS[2]}" | cut -c 1-4)

export OPTIONS=("latest recommended version -> $latest_recommended" "latest version -> $latest" "choose custom version" "do nothing")

bashSelect

case $? in
     0 )
        runtime_link="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[0]}";;
     1 )
        runtime_link="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSIONS[2]}";;
     2 )
        clear
        read -p "Enter the download link: " runtime_link
        ;;
     3 )
        exit 0;;
esac

# Ausführen des Installations- oder Update-Skripts basierend auf der Auswahl
if [[ "$action" == "install" ]]; then
  bash <(curl -s https://raw.githubusercontent.com/DeinGithubUsername/DeinRepo/main/install.sh) "$runtime_link"
else
  bash <(curl -s https://raw.githubusercontent.com/DeinGithubUsername/DeinRepo/main/update.sh) "$runtime_link"
fi
