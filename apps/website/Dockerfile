FROM dart:3.11.5 AS build

WORKDIR /app
COPY . .

RUN dart pub get

WORKDIR /app/apps/website
RUN dart pub global activate jaspr_cli 0.23.1
RUN dart pub global run jaspr_cli:jaspr build

FROM busybox:1.36.1-uclibc AS runtime
RUN adduser -D -u 1000 -g 'www' www
WORKDIR /www
COPY --from=build /app/apps/website/build/jaspr .
RUN chown -R www:www /www

USER www
EXPOSE 8080
CMD ["httpd", "-f", "-p", "8080"]
