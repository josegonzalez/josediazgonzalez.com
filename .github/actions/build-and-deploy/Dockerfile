FROM ruby:3.4-alpine

RUN apk --no-cache add bash build-base git linux-headers sed
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
