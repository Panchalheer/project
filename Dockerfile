# 1. Use an official lightweight Nginx image as the base
FROM nginx:alpine

# 2. Remove the default Nginx website
RUN rm -rf /usr/share/nginx/html/*

# 3. Copy your Flutter web build into Nginx’s web folder
COPY build/web /usr/share/nginx/html

# 4. Expose port 80 to the world
EXPOSE 80

# 5. Start Nginx automatically when the container starts
CMD ["nginx", "-g", "daemon off;"]