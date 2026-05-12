FROM ghcr.io/cirruslabs/flutter:3.41.7 AS build

WORKDIR /app

RUN build_arch="$(uname -m)" && case "$build_arch" in x86_64|amd64) tailwind_arch=x64 ;; aarch64|arm64) tailwind_arch=arm64 ;; *) echo "Unsupported build architecture: $build_arch" >&2; exit 1 ;; esac && curl -fsSL "https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-${tailwind_arch}" -o /usr/local/bin/tailwindcss
RUN chmod +x /usr/local/bin/tailwindcss
RUN tailwindcss --help >/dev/null

COPY . .

RUN flutter config --enable-web
RUN flutter pub get

WORKDIR /app/apps/website
RUN dart pub global activate jaspr_cli 0.23.1
RUN dart pub global run jaspr_cli:jaspr build

WORKDIR /app/apps/dashboard
RUN flutter build web --release --base-href /demo/

FROM nginx:1.27-alpine AS runtime

RUN rm -rf /usr/share/nginx/html/*

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/apps/website/build/jaspr/ /usr/share/nginx/html/
COPY --from=build /app/apps/dashboard/build/web/ /usr/share/nginx/html/demo/

EXPOSE 80
