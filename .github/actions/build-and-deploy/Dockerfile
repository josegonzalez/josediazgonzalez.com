FROM jekyll/builder:4.2.2

RUN apk --no-cache add sed
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
