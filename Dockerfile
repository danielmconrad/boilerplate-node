ARG GIT_SHA=null
ARG NODE_VERSION=18.10
ARG RUBY_VERSION=3.1.2


# Base
# ------------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS client-base
WORKDIR /client

ENV PATH="/node_modules/.bin:${PATH}"

RUN apk update && apk upgrade && apk add --update --no-cache \
  bash g++ make


# Dev
# ------------------------------------------------------------------------------
FROM client-base AS client-dev
WORKDIR /client

COPY client/.yarnrc client/package.json client/yarn.lock ./
RUN yarn install &> /dev/null


# Build
# ------------------------------------------------------------------------------
FROM client-dev as client-build

COPY client/ .

RUN yarn build


# Web Release/Production
# ------------------------------------------------------------------------------
FROM client-base as client-release

ARG GIT_SHA

COPY Makefile ./

COPY --from=build /client/build/ /web/public/

RUN date -u > BUILD_TIME
RUN echo "${GIT_SHA}" | cat > ./GIT_SHA

CMD yarn start
