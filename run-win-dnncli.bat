start .\bin\windows\julius.exe -C main.jconf -C am-dnn.jconf -demo -charconv utf-8 sjis -input vecnet
timeout 10
start python .\bin\common\dnnclient.py dnnclient.conf
timeout 5
start .\bin\windows\adintool -in mic -out vecnet -server 127.0.0.1 -paramtype FBANK_D_A_Z -veclen 120 -htkconf model\dnn\config.lmfb -port 5532 -cvn -cmnload model\dnn\norm -cmnnoupdate
