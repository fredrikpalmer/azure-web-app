FROM hashicorp/terraform:0.14.9

RUN apk add --no-cache curl bash openssl  
RUN apk add python3 py3-pip && \
    apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python3-dev make

RUN pip3 install azure-cli

WORKDIR /terraform

ENTRYPOINT [ "terraform" ]