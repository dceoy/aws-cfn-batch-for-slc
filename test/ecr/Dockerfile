FROM quay.io/centos/centos:stream

ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /tmp/awscli.zip
ADD https://raw.githubusercontent.com/dceoy/s3-sync-entrypoint/main/s3-sync-entrypoint /usr/local/bin/s3-sync-entrypoint

RUN set -e \
      && dnf -y upgrade \
      && dnf -y install \
        curl unzip \
      && dnf clean all \
      && rm -rf /var/cache/dnf/*

RUN set -e \
      && unzip -d /tmp /tmp/awscli.zip \
      && /tmp/aws/install \
      && rm -rf /tmp/awscli.zip /tmp/aws

ENV INPUT_DATA_DIR /input
ENV OUTPUT_DATA_DIR /output

RUN set -e \
      && mkdir "${INPUT_DATA_DIR}" "${OUTPUT_DATA_DIR}" \
      && chmod +x /usr/local/bin/s3-sync-entrypoint

ENTRYPOINT ["/usr/local/bin/s3-sync-entrypoint"]
CMD ["/usr/bin/curl", "--version"]
