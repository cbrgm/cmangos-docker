FROM gcc:7.3.0

WORKDIR /output
RUN apt-get update -qq && \
    apt-get install openssl libssl-dev cmake -y

COPY entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
