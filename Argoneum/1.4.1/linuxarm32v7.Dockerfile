# Use manifest image which support all architecture
FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV AGM_VERSION 1.4.1
ENV AGM_URL https://github.com/Argoneum/argoneum/releases/download/v1.4.1.0/argoneum-1.4.1-arm-linux-gnueabihf.tar.gz
ENV AGM_SHA256 826ceeed188dc1e54d0c982be713bd9d161b0e40f85a485a0a938d8e4bf229bf
#ENV AGM_ASC_URL https://github.com/Argoneum/argoneum/releases/download/v1.4.0/SHA256SUMS.asc
#ENV AGM_PGP_KEY 63a96b406102e091
	# && echo "$AGM_SHA256 dash.tar.gz" | sha256sum -c - \
	# && gpg --keyserver keyserver.ubuntu.com --recv-keys "$AGM_PGP_KEY" \
	# && wget -qO dash.asc "$AGM_ASC_URL" \
	# && gpg --verify dash.asc \

# install argoneum binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO argoneum.tar.gz "$AGM_URL" \
	&& echo "$AGM_SHA256 argoneum.tar.gz" | sha256sum -c - \
	&& mkdir bin \
	&& tar -xzvf argoneum.tar.gz -C /tmp/bin --strip-components=2 "argoneum-$AGM_VERSION/bin/argoneum-cli" "argoneum-$AGM_VERSION/bin/argoneumd" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-armhf" \
	&& echo "171b4a2decc920de0dd4f49278d3e14712da5fa48de57c556f99bcdabe03552e gosu" | sha256sum -c -

# Making sure the builder build an arm image despite being x64
FROM arm32v7/debian:stretch-slim

COPY --from=builder "/tmp/bin" /usr/local/bin
#EnableQEMU COPY qemu-arm-static /usr/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.argoneum \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.argoneum

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9898 9899 19898 19899
CMD ["argoneumd"]
