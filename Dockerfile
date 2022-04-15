FROM hashicorp/terraform:1.1.8

RUN apk add py3-pip && \
    apk add gcc musl-dev python3-dev libffi-dev openssl-dev cargo make

RUN pip install --upgrade pip
RUN pip install azure-cli

WORKDIR /terraform

ENTRYPOINT [ "terraform" ]