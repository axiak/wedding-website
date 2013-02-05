#!/bin/bash
cd $(dirname "$0")

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

