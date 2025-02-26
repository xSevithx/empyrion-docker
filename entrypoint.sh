#!/bin/bash -ex
#Notes: steamcmd +login anonymous +force_install_dir c:\Empyrion +app_update 530870 validate +quit
##Empyrion AppID 383120
##RE 1.10 2918811239
[ "$UID" != 0 ] || {
    mkdir -p ~user/Steam
    chown user: ~user/Steam
    runuser -u user "$0" "$@"
    exit 0
}

GAMEDIR="$HOME/Steam/steamapps/common/Empyrion - Dedicated Server/DedicatedServer"

cd "$HOME"
STEAMCMD="./steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous $STEAMCMD"
[ -z "$BETA" ] || STEAMCMD="$STEAMCMD -beta experimental"

# eval to support quotes in $STEAMCMD
eval "$STEAMCMD +app_update 530870 +quit"

CLONEDIR="/home/user/Steam/steamapps/common/Empyrion - Dedicated Server/Content/Scenarios"
REPO_URL="https://github.com/xSevithx/Empyrion-REFiles.git"
REPO_DIR="ReforgedEden"

# Check if the repository directory already exists
if [ ! -d "$CLONEDIR/$REPO_DIR" ]; then
    cd "$CLONEDIR"
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Repository directory '$REPO_DIR' already exists. Skipping clone."
fi

#End RE Clone

mkdir -p "$GAMEDIR/Logs"

rm -f /tmp/.X1-lock
Xvfb :1 -screen 0 800x600x24 &
export WINEDLLOVERRIDES="mscoree,mshtml="
export DISPLAY=:1

cd "$GAMEDIR"

[ "$1" = "bash" ] && exec "$@"

sh -c 'until [ "`netstat -ntl | tail -n+3`" ]; do sleep 1; done
sleep 5 # gotta wait for it to open a logfile
tail -F Logs/current.log ../Logs/*/*.log 2>/dev/null' &

/opt/wine-staging/bin/wine ./EmpyrionDedicated.exe -batchmode -nographics -dedicated /dedicated.yaml -logFile Logs/current.log "$@" &> Logs/wine.log
