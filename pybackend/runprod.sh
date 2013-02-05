#!/bin/bash
cd $(dirname "$0")

source /usr/local/bin/virtualenvwrapper.sh &>/dev/null
source /usr/bin/virtualenvwrapper.sh &>/dev/null

workon wedding

pip install -r requirements.pip --upgrade


# 1 + number of CPUs
NUM_PROCS=$(($(grep proc /proc/cpuinfo | wc -l) + 1))

i=0

while [ $(pgrep -c uwsgi) -ne 0 ]; do
    if [[ $i -gt 4 ]]; then
        killall -9 uwsgi
    else
        killall uwsgi
    fi
    sleep .25
    i=$((i + 1))
done

uwsgi --master -b 32768 -d ./logs/uwsgi.log -pp $VIRTUAL_ENV -H $VIRTUAL_ENV --socket 127.0.0.1:3031 --processes $NUM_PROCS --module wedding:app

i=0

while [ $(ps aux | grep celeryd | grep -cv grep) -ne 0 ]; do
    if [[ $i -gt 4 ]]; then
        ps aux | grep celeryd | grep -v grep | awk '{print $2}' | xargs -n 32 kill -9
    else
        ps aux | grep celeryd | grep -v grep | awk '{print $2}' | xargs -n 32 kill
    fi
    sleep .25
    i=$((i + 1))
done

nohup python manage.py celeryd -c 5 -f ./logs/celeryd &>/dev/null &
