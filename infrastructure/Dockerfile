FROM alpine:3.22
COPY --from=ghcr.io/opentofu/opentofu:1.13.2 /usr/local/bin/tofu /usr/local/bin/tofu
WORKDIR /src
RUN apk add --no-cache --update python3 py3-pip 
RUN apk add --no-cache --update --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo make && pip3 install --no-cache-dir --prefer-binary --break-system-packages azure-cli && apk del build
COPY . .
ENTRYPOINT ["/usr/local/bin/tofu"]
