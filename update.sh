#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

runtime_link=$1

status(){
  clear
  echo -e "${green}$@...${nc}"
  sleep 1
}

runCommand(){
    COMMAND=$1

    if [[ ! -z "$2" ]]; then
      status "$2"
    fi

    eval "$COMMAND";
    BASH_CODE=$?
    if [ $BASH_CODE -ne 0 ]; then
      echo -e "${red}An error occurred:${nc} ${white}${COMMAND}${nc}${red} returned${nc} ${white}${BASH_CODE}${nc}"
      exit ${BASH_CODE}
    fi
}

# Einbindung der BashSelect-Funktionalität
source <(curl -s https://raw.githubusercontent.com/LukeCodingDeveloper/BashSelect.sh/main/BashSelect.sh)
clear

# Auswahl des Alpine-Verzeichnisses
status "Select the alpine directory:"
readarray -t directories <<< $(find / -name "alpine")
export OPTIONS=("${directories[@]}")

bashSelect

selected_index=$?
dir="${directories[$selected_index]}/.."

# Überprüfen, ob ein Prozess auf Port 40120 läuft
lsof -i :40120 > /dev/null
if [[ $? -eq 0 ]]; then
  status "It looks like something is running on the default TxAdmin port. Can we stop/kill it?" "/"
  export OPTIONS=("Kill PID on port 40120" "Exit the script")
  bashSelect
  case $? in
    0 )
      status "Killing PID on port 40120"
      runCommand "apt -y install psmisc"
      runCommand "fuser -4 40120/tcp -k"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

# Löschen des alpine-Verzeichnisses
echo "${red}Deleting ${nc}alpine"
sleep 1
runCommand "rm -rf $dir/alpine"
clear

# Löschen der run.sh Datei
echo "${red}Deleting ${nc}run.sh"
sleep 1
runCommand "rm -f $dir/run.sh"
clear

# Herunterladen der fx.tar.xz Datei
echo "Downloading ${yellow}fx.tar.xz${nc}"
runCommand "wget --directory-prefix=$dir $runtime_link"
echo "${green}Success${nc}"
sleep 1
clear

# Entpacken der fx.tar.xz Datei
echo "Unpacking ${yellow}fx.tar.xz${nc}"
runCommand "tar xf $dir/fx.tar.xz -C $dir"
echo "${green}Success${nc}"
sleep 1
clear

# Löschen der fx.tar.xz Datei
runCommand "rm -f $dir/fx.tar.xz"
echo "${red}Deleting ${nc}fx.tar.xz"
sleep 1
clear

echo "${green}Update successful${nc}"
