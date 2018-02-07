#!/bin/sh

get_unicorn_pid() {
    PID=`cat unicorn.pid`
    return `cat unicorn.pid`
}

run_unicorn() {
    ((python3 strandtest.py) & echo $! > unicorn.pid &)
    chown pi: unicorn.pid
}

restart_unicorn_if_dead() {
    PID=`cat unicorn.pid`
    echo "IN RESTART: Current unicorn pid: $PID"
    if [ ! -e /proc/$PID -a /proc/$PID/exe ]; then
	echo "Dead unicorn detected. Resurrecting now..."
        run_unicorn
    fi
}

kill_unicorn() {
    PID=`cat unicorn.pid`
    echo "Killing unicorn."
    kill -9 $PID
}

cd /home/pi/src/UnicornReborn

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

echo "Birthing current unicorn."
run_unicorn
sleep 5
restart_unicorn_if_dead
sleep 5

echo "Starting detection loop."
while :
do
    sleep 60
    echo "Detecting if unicorn is dead or obsolete."
 
    if [ $LOCAL = $REMOTE ]; then
        echo "Unicorn is not obsolete."
 	restart_unicorn_if_dead 
    elif [ $LOCAL = $BASE ]; then
        echo "Killing obsolete unicorn."
        git pull
	kill_unicorn
	sleep 1
	restart_unicorn_if_dead
	sleep 2
	restart_unicorn_if_dead
	sleep 3
	restart_unicorn_if_dead
    fi
done
