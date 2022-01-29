#!/bin/bash

LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu/:/lib/x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu
CFLAGS=${CFLAGS:-'-O5 -Q'}
CXXFLAGS=${CXXFLAGS:-$CFLAGS}
THREADS="$THREADS"

MAIN()
{

        installDepends
        getSources

        makeOpenSSL
        makeC-ares
        makeCurl

        makeXMLRPC-c
        makeLibTorrent
        makeRTorrent
}

function _exitIfFailed()
{
        if [ $1 -ne 0 ]
        then
                exit -1
        fi
}

function _currentStatus()
{
    numlines=$(tput lines)
    numcols=$(tput cols)
    numcols=$(expr $numcols - 1)
    separator_line=$(for i in $(seq 0 $numcols);do printf "%s" "-";done;printf "\n")
    tput cup $numlines
    echo $separator_line
    echo $1
}

function installDepends()
{
        _currentStatus "1of8 Installing Dependencies"

        apt-get -y -q install git build-essential automake libtool libsigc++-2.0-dev libncurses-dev libxml2-dev pkg-config software-properties-common

        _exitIfFailed $?
}

function getSources()
{
        # Getting Ducks in a row, change versions here
        _currentStatus "2of8 Grabbing Sources"

        git clone git://git.openssl.org/openssl.git

        git clone https://github.com/c-ares/c-ares.git

        git clone https://github.com/curl/curl.git

        git clone https://github.com/mirror/xmlrpc-c

        wget -O - https://github.com/rakshasa/rtorrent-archive/raw/master/libtorrent-0.13.8.tar.gz|tar xz
        mv libtorrent-0.13.8 libtorrent

        # Vanilla
        wget -O - https://github.com/rakshasa/rtorrent-archive/raw/master/rtorrent-0.9.8.tar.gz| tar zx
        mv rtorrent-0.9.8 rtorrent

        if test -f ../secretSauce.sh
        then
            bash ../secretSauce.sh
        fi

        result=$(test -d openssl && test -d c-ares && test -d curl && test -d curl && test -d xmlrpc-c && test -d libtorrent && test -d rtorrent ; echo $? )


        _exitIfFailed $result
}


function makeOpenSSL()
{
        _currentStatus "3of8 Making OpenSSL Libraries"

        cd openssl

        ./config -fPIC  shared enable-ec_nistp_64_gcc_128
        make $THREADS && make install

        _exitIfFailed $?

        strip --strip-unneeded *lib*.so*

        cp  lib*.so* /usr/local/lib

        cd ..
}

function makeC-ares()
{
        cd c-ares
        _currentStatus "4of8 Making C-Ares Library"
        ./buildconf
        ./configure --enable-nonblocking --enable-shared --disable-static CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" -fPIC
        make $THREADS && make install

        _exitIfFailed $?

        strip --strip-unneeded /usr/local/lib/libcares.*

        cd ..
}

function makeCurl()
{
        cd curl
        _currentStatus "5of8 Making Curl"

        ./buildconf
        ./configure --enable-ares --with-zlib --enable-shared --with-openssl --disable-static CFLAGS="$CFLAGS -fPIC" CXXFLAGS="$CXXFLAGS -fPIC"
        make $THREADS  && make install

        _exitIfFailed $?

        strip --strip-unneeded /usr/local/lib/libcurl.*

        cd ..
}

function makeXMLRPC-c()
{
        cd xmlrpc-c/advanced
        _currentStatus "6of8 Making XMLRPC Library."

        ./configure -disable-wininet-client  --disable-libwww-client  --enable-abyss-server  --disable-cplusplus  --disable-abyss-threads  --disable-cgi-server  --with-libwww-ssl --enable-shared --disable-static CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" --enable-c++0x

        make $THREADS && make install

        _exitIfFailed $?

        strip --strip-unneeded /usr/local/lib/libxml*.*

        cd ../..
}

function makeLibTorrent
{
        cd libtorrent
        _currentStatus "7of8 Making LibTorrent"


        ./configure --with-posix-fallocate --disable-debug --enable-shared --enable-openssl --enable-largefile --enable-c++0x --enable-interrupt-socket --disable-static CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
        make $THREADS && make install


        _exitIfFailed $?

        strip --strip-unneeded /usr/local/lib/libtorrent*.*

        cd ..
}

function makeRTorrent()
{

        cd rtorrent
        _currentStatus "8of8 Making rTorrent *Final Step*"

        ./autogen.sh
        ./configure --disable-debug  --with-xmlrpc-c  --with-pic --enable-threads --enable-c++0x --disable-static CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"


        make $THREADS

        strip --strip-unneeded src/rtorrent

        make install

        _exitIfFailed $?

        ldconfig


        cd ..
}


### Body

        exec &> >(tee -a BUILD_LOG.$$)

        mkdir WorkingDirectory
        cd WorkingDirectory

        MAIN

        rtorrent -h |grep version
        ldd /usr/local/bin/rtorrent
        echo
        ls -sh /usr/local/bin/rtorrent
        echo "Complete"
exit 0
