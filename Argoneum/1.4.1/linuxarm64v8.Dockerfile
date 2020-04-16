# Use manifest image which support all architecture
FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV AGM_VERSION 1.4.1
ENV AGM_URL https://github.com/Argoneum/argoneum/releases/download/v1.4.1.0/argoneum-1.4.1-aarch64-linux-gnu.tar.gz
ENV AGM_SHA256 9ad54653bd488826d5656fb8212677228469790e862fd5e279d650b77f21d68d
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
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-arm64" \
	&& echo "5e279972a1c7adee65e3b5661788e8706594b458b7ce318fecbd392492cc4dbd gosu" | sha256sum -c -

# Making sure the builder build an arm image despite being x64
FROM arm64v8/debian:stretch-slim

COPY --from=builder "/tmp/bin" /usr/local/bin
#EnableQEMU COPY qemu-aarch64-static /usr/bin

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
