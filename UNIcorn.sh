#!/bin/sh

REPO_REMOTE=git@github.com:emmatoday/UnicornReborn
SRC_DIR=/home/pi/src
REPO_DIR=${SRC_DIR}/UnicornReborn
REPO_TEMP_DIR=${SRC_DIR}/UnicornReborn.temp

get_unicorn_pid() {
    PID=`cat unicorn.pid` || PID=55555
    return $PID
}

run_unicorn() {
    ((python3 strandtest.py) & echo $! > unicorn.pid &)
    chown pi: unicorn.pid
}

restart_unicorn_if_dead() {
    PID=`cat unicorn.pid` || PID=55555
    # echo "IN RESTART: Current unicorn pid: $PID"
    if ([ ! -f /home/pi/src/UnicornReborn/unicorn.pid] || [ ! -e /proc/$PID -a /proc/$PID/exe ]); then
	echo "Dead unicorn detected. Resurrecting now..."
        run_unicorn
    fi
}

kill_unicorn() {
    PID=`cat unicorn.pid`
    echo "Killing unicorn."
    kill -9 $PID
}

create_temp_repo() {
    cd ${SRC_DIR}
    git clone ${REPO_REMOTE} ${REPO_TEMP_DIR}
    cd ${REPO_DIR}
}

update_code() {
    echo "Starting code update."

    # REMOVE EXISTING TEMP DIR IF IT EXISTS
    rm -Rf $REPO_TEMP_DIR || true

    # CREATE TEMP REPO IF NEEDED AND UPDATE IT
    create_temp_repo


    echo "Pulling in changes from temp repo."
    cd $REPO_DIR
    git pull temp master || echo "Error pulling in changes from temp repo."

    rm -Rf $REPO_TEMP_DIR || echo "Error removing temp repo."
}

cd /home/pi/src/UnicornReborn

echo "Birthing current unicorn."
restart_unicorn_if_dead
sleep 5
restart_unicorn_if_dead
sleep 5

echo "Starting detection loop."
while :
do
    sleep 30
    echo "Detecting if unicorn is dead or obsolete."

    git fetch 

    UPSTREAM=${1:-'@{u}'}
    echo $UPSTREAM
    LOCAL=$(git rev-parse @{0})
    echo $LOCAL
    REMOTE=$(git rev-parse "$UPSTREAM")
    echo $REMOTE

    if [ $LOCAL = $REMOTE ]; then
        echo "Unicorn is not obsolete."
 	restart_unicorn_if_dead 
    else
        echo "Killing obsolete unicorn."
	update_code
	kill_unicorn
	sleep 1
        echo "Birthing current unicorn."
	restart_unicorn_if_dead
	sleep 2
	restart_unicorn_if_dead
	sleep 3
	restart_unicorn_if_dead
    fi
done
