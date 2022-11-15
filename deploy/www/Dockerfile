FROM hexpm/elixir:1.14.2-erlang-25.1.2-ubuntu-bionic-20210930

RUN mkdir -p /scripts
COPY ./deploy/www/docker-entry.sh /scripts

EXPOSE 80

ARG DATABASE_URL=${DATABASE_URL}
ARG PORT=${PORT}
ARG SECRET_KEY_BASE=${SECRET_KEY_BASE}
ARG MIX_ENV=${MIX_ENV}
ARG ORIGIN=${ORIGIN}
ARG HOST=${HOST}
ARG TZ=${TZ}
ARG APP_NAME=${APP_NAME}
ARG DEFAULT_SPACE=${DEFAULT_SPACE}
ARG PICTURE_LOCATION=${PICTURE_LOCATION}
ARG PICTURES_PATH=${PICTURES_PATH}
ARG DATASOURCES=${DATASOURCES}

ENV DATABASE_URL=${DATABASE_URL} \
    PORT=${PORT} \
    SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    MIX_ENV=${MIX_ENV} \
    ORIGIN=${ORIGIN} \
    HOST=${HOST} \
    TZ=${TZ} \
    APP_NAME=${APP_NAME} \
    DEFAULT_SPACE=${DEFAULT_SPACE} \
    PICTURE_LOCATION=${PICTURE_LOCATION} \
    PICTURES_PATH=${PICTURES_PATH} \
    DATASOURCES=${DATASOURCES}

RUN apt-get update && apt-get install --no-install-suggests -y \
    curl imagemagick

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash

RUN apt-get update && apt-get install -y \
    nodejs

#RUN usermod -u 1000 root
#USER www-data

RUN mkdir -p /var/nameguess

COPY ./config/config.exs ./config/$MIX_ENV.exs /var/nameguess/config/
COPY ./mix.exs mix.lock /var/nameguess/

WORKDIR /var/nameguess/

RUN rm -Rf /var/nameguess/_build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only $MIX_ENV && \
    mix deps.compile

COPY / /var/nameguess/

WORKDIR /var/nameguess/assets

RUN npm install

WORKDIR /var/nameguess/

# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
RUN mix assets.deploy

RUN mix release prod

#CMD ["_build/prod/rel/prod/bin/prod", "start"]

WORKDIR /scripts
RUN chmod +x ./docker-entry.sh
CMD ["./docker-entry.sh"]
