FROM nginx:alpine

# Copy the built web app to nginx directory
COPY build/web /usr/share/nginx/html

# Create icons directory if it doesn't exist
RUN mkdir -p /usr/share/nginx/html/icons

# Copy icons
COPY build/web/icons/apple-touch-icon.png /usr/share/nginx/html/icons/
COPY build/web/icons/favicon-96x96.png /usr/share/nginx/html/icons/
COPY build/web/icons/favicon.ico /usr/share/nginx/html/icons/
COPY build/web/icons/favicon.svg /usr/share/nginx/html/icons/
COPY build/web/icons/web-app-manifest-192x192.png /usr/share/nginx/html/icons/
COPY build/web/icons/web-app-manifest-512x512.png /usr/share/nginx/html/icons/

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Update nginx config to listen on port 8080
RUN sed -i 's/80/8080/g' /etc/nginx/conf.d/default.conf
