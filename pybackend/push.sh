#!/bin/bash
cd $(dirname "$0")
cd ..
rsync -avz pybackend/ server.yaluandmike.com:~/pybackend
