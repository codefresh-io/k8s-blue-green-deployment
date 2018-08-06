FROM golang:alpine AS build-env
ADD . /src
RUN cd /src && go build -o hello-web

FROM alpine

EXPOSE 8080

WORKDIR /app
COPY --from=build-env /src/hello-web /app/
ENTRYPOINT ./hello-web

