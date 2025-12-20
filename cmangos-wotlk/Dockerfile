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
	libmariadbclient-dev \
	libreadline-dev \
	libncurses-dev \
	libbz2-dev \
	ccache \
	wget

RUN ln -s /usr/bin/ccache /usr/local/bin/gcc \ 
	&& ln -s /usr/bin/ccache /usr/local/bin/g++ \
	&& ln -s /usr/bin/ccache /usr/local/bin/cc \
        && ln -s /usr/bin/ccache /usr/local/bin/c++

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

ENV HOME_DIR="/home/mangos"
ENV MANGOS_DIR="/opt/mangos"
RUN useradd --home "${HOME_DIR}" --create-home \
            --comment "MaNGOS" \
            --user-group mangos

WORKDIR "${MANGOS_DIR}"

ARG EXPANSION
COPY --from=builder /cmangos/run "${MANGOS_DIR}"
COPY runner/entrypoint.sh /

ENV VOLUME_DIR="/var/lib/mangos"
ENV TMPDIR="${VOLUME_DIR}/tmp"			
RUN mkdir -p "${VOLUME_DIR}" \
	&& mkdir -p "${TMPDIR}" \
	&& mkdir -p "${MANGOS_DIR}/etc" \
	&& chown -R mangos:mangos "${VOLUME_DIR}" \
	&& chown -R mangos:mangos "${MANGOS_DIR}"

ENV MANGOS_DBHOST="host.docker.internal"
ENV MANGOS_DBPORT="3306"
ENV MANGOS_DBUSER="mangos"
ENV MANGOS_DBPASS=""

ENV MANGOS_WORLD_DBNAME="wotlkmangos"
ENV MANGOS_CHARACTERS_DBNAME="wotlkcharacters"
ENV MANGOS_LOGS_DBNAME="wotlklogs"
ENV MANGOS_REALMD_DBNAME="wotlkrealmd"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
EXPOSE 3443 3724 7878 8085 8086	
