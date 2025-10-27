# Dockerfile pour build web de l'application Solitaire Klondike
FROM node:18-alpine AS web-builder

# Installer Flutter
RUN apk add --no-cache curl git unzip xz
RUN curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.5-stable.tar.xz | tar -xJ -C /opt
ENV PATH="/opt/flutter/bin:${PATH}"

# Configurer Flutter
RUN flutter config --enable-web
RUN flutter doctor

# Copier les fichiers sources
WORKDIR /app
COPY pubspec.* ./
COPY lib/ lib/
COPY assets/ assets/
COPY analysis_options.yaml .
COPY l10n.yaml .

# Installer les dépendances et builder
RUN flutter pub get
RUN flutter build web --release

# Image finale Nginx pour servir l'app
FROM nginx:alpine
COPY --from=web-builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]