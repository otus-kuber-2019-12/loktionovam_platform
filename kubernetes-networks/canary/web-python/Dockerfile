FROM python:latest

# This docker image used to simulate canary pod
LABEL maintainer="loktionovam@gmail.com"

ENV PORT=8000

RUN mkdir /app

WORKDIR /app
EXPOSE ${PORT}
CMD python -m http.server ${PORT}
