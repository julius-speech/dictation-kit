#! /bin/sh

./bin/linux/julius -C main.jconf -C am-gmm.jconf -demo -charconv utf-8 euc-jp $*
