#!/bin/bash
cd $(dirname "$0")
cd ..
rsync -avz pybackend/ server.yaluandmike.com:~/pybackend
ssh server.yaluandmike.com "~/pybackend/runprod.sh"
