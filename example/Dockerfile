#FROM golang:alpine AS build-env
#ADD . /src
#RUN cd /src && go build -o hello-web

# final stage
#FROM alpine

#EXPOSE 8080

#WORKDIR /app
#COPY --from=build-env /src/hello-web /app/
#ENTRYPOINT ./hello-web

FROM golang:alpine
EXPOSE 8080
WORKDIR /app
ADD . /app
RUN cd /app && go build -o hello-web
ENTRYPOINT ./hello-web