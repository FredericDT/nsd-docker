###########
# Builder #
###########
FROM library/debian:bookworm-slim AS builder
RUN apt update && apt install -y build-essential wget tar \
    libevent-dev libssl-dev
WORKDIR /opt
RUN useradd -m -s /bin/false nsd && \
    wget https://www.nlnetlabs.nl/downloads/nsd/nsd-4.11.1.tar.gz && tar -zxf nsd-4.11.1.tar.gz 
RUN cd nsd-4.11.1 && \
    ./configure \ 
        --prefix=/ \
        --enable-bind8-stats \
        --enable-zone-stats \
        --enable-ratelimit \
        --enable-ratelimit-default-is-off \
        --with-user=nsd \
        --with-libevent \
        --with-ssl \
    && \ 
    make && make install
RUN wget http://www.internic.net/domain/root.zone

##########
# Worker #
##########
FROM library/debian:bookworm-slim
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN apt update && apt install -y libevent-2.1-7 libssl3 tzdata && \ 
    apt clean
COPY --from=builder /sbin/nsd /sbin/nsd
COPY --from=builder /sbin/nsd-control /sbin/nsd-control
RUN mkdir -p /etc/nsd
RUN useradd -m -s /bin/false nsd
COPY --from=builder /opt/root.zone /etc/nsd/root.zone
COPY --from=builder /opt/nsd-4.11.1/nsd.conf.sample.in /etc/nsd/nsd.conf
ENTRYPOINT ["/sbin/nsd"]
CMD ["-d"]
EXPOSE 53/udp
