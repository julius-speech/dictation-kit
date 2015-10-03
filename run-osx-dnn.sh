#! /bin/sh

./bin/osx/julius -C main.jconf -C am-dnn.jconf -demo $* &
sleep 10
xterm -e python ./bin/common/dnnclient.py dnnclient.conf &
sleep 2
xterm -e ./bin/osx/adintool -in mic -out vecnet -server 127.0.0.1 -paramtype FBANK_D_A_Z -veclen 120 -htkconf model/dnn/config.lmfb.40ch.jnas -port 5532 -cvn -cmnload model/dnn/norm.jnas

kill 0
