# syntax=docker/dockerfile:1

FROM --platform=linux/amd64 ocaml/opam:alpine-3.18-ocaml-4.14

WORKDIR /artifact
COPY links links
COPY tests tests
COPY run-tests.py run-tests.py
COPY README.md README.md

USER root
RUN apk update && apk upgrade && \
    apk add gmp-dev && \
    chown opam:nogroup -R /artifact/links

USER opam
WORKDIR /artifact/links
# RUN opam update
RUN opam install dune -y
RUN opam pin add links . -n
RUN opam install links --deps-only -y
RUN make all
RUN sudo ln -s /artifact/links/linx /usr/local/bin/
WORKDIR /artifact

CMD [ "bash" ]