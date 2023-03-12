FROM hexpm/elixir-arm64:1.13.0-erlang-25.3-alpine-3.17.2 as build
RUN apk add --update git && apk add curl && apk --update add coreutils && apk add --update make
RUN mkdir /app

WORKDIR /app

RUN mix local.hex --force                                                                                                                                                
RUN mix local.rebar --force  

ENV PATH="${PATH}:/app"
ENV MIX_ENV="prod"

COPY ./lib ./lib
COPY ./deps ./deps
COPY ./test ./test
COPY ./config ./config
COPY ./.credo.exs ./.credo.exs
COPY ./coveralls.json ./coveralls.json
COPY ./Makefile ./Makefile
COPY ./mix.exs ./mix.exs
COPY ./mix.lock ./mix.lock
COPY ./mix.exs ./mix.exs
COPY ./.formatter.exs ./.formatter.exs

RUN make init

ENTRYPOINT [ "/bin/sh" ]