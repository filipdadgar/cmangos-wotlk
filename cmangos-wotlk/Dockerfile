FROM ubuntu:20.04 AS builder
RUN apt-get update -y && apt-get upgrade -y

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
	build-essential \ 
	git \
	cmake \
	libtbb-dev \
	openssl \
	libssl-dev \
	libace-dev \
	p7zip-full \ 
	zlib1g-dev \
	libcurl4-openssl-dev \
	libboost-all-dev \
	libmysqlclient-dev \
	libbz2-dev \
	ccache \
	wget

RUN ln -s /usr/bin/ccache /usr/local/bin/gcc \ 
	&& ln -s /usr/bin/ccache /usr/local/bin/g++ \
	&& ln -s /usr/bin/ccache /usr/local/bin/cc \
        && ln -s /usr/bin/ccache /usr/local/bin/c++

RUN export ACE_ROOT=/usr/include/ace && export TBB_ROOT_DIR=/usr/include/tbb
WORKDIR /cmangos
RUN mkdir build run
RUN git clone https://github.com/cmangos/mangos-wotlk.git mangos

WORKDIR /cmangos/build
RUN cmake -DDEBUG=0 -DBUILD_EXTRACTORS=ON -DBUILD_PLAYERBOT=ON -DCMAKE_INSTALL_PREFIX=../run ../mangos
RUN make -j`nproc`
RUN make install
WORKDIR /cmangos
RUN mv run/etc/mangosd.conf.dist run/etc/mangosd.conf
RUN mv run/etc/realmd.conf.dist run/etc/realmd.conf
RUN mv run/etc/playerbot.conf.dist run/etc/playerbot.conf

FROM ubuntu:20.04
RUN apt-get update && apt-get upgrade -y 

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y \
        libssl-dev \
	wget \
	mariadb-client \
	libmariadb-dev \
	screen \
	git


COPY --from=builder /cmangos/run /cmangos


ENV SERVERIP=192.168.1.212
ENV STARTLEVEL=60
ENV MONEY=1000000
ENV SKIPCIN=1

ADD start.sh /cmangos/run/
RUN chmod +x /cmangos/run/start.sh

WORKDIR /cmangos/bin
EXPOSE 8085 3724


CMD ["/cmangos/run/start.sh"]