#!/bin/bash
ssh server.yaluandmike.com "rm -rf ~/backend-old; mv ~/backend-current ~/backend-old; mkdir ~/backend-current/"
scp dist/weddingbackend*.zip server.yaluandmike.com:~/backend-current/
ssh server.yaluandmike.com "cd ~/backend-current/; unzip *.zip"
ssh server.yaluandmike.com "~/start-backend"
