###########
# Builder #
###########
FROM debian:buster-slim AS builder
RUN sed -i -E 's+(deb|security).debian.org+mirrors.bupt.edu.cn+g' /etc/apt/sources.list
RUN apt update && apt install -y build-essential wget tar \
    libevent-dev libssl-dev
WORKDIR /opt
RUN useradd -m -s /bin/false nsd && \
    wget https://www.nlnetlabs.nl/downloads/nsd/nsd-4.3.7.tar.gz && tar -zxf nsd-4.3.7.tar.gz 
RUN cd nsd-4.3.7 && \
    ./configure \ 
        --prefix=/ \
        --enable-root-server \
        --enable-bind8-stats \
        --enable-ratelimit \
        --with-user=nsd \
        --with-libevent \
        --with-ssl \
    && \ 
    make && make install
RUN wget http://www.internic.net/domain/root.zone

##########
# Worker #
##########
FROM debian:buster-slim
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN sed -i -E 's+(deb|security).debian.org+mirrors.bupt.edu.cn+g' /etc/apt/sources.list
RUN apt update && apt install -y libevent-2.1-6 libssl1.1 tzdata && \ 
    apt clean
COPY --from=builder /sbin/nsd /sbin/nsd
COPY --from=builder /sbin/nsd-control /sbin/nsd-control
RUN mkdir -p /etc/nsd
RUN useradd -m -s /bin/false nsd
COPY --from=builder /opt/root.zone /etc/nsd/root.zone
ADD ./nsd.conf /etc/nsd/nsd.conf
ENTRYPOINT ["/sbin/nsd"]
CMD ["-d"]
EXPOSE 53/udp
