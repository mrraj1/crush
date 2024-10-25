# Use the official Nginx image as a base image
FROM nginx:latest

# Copy static website files to the Nginx HTML directory
COPY . /usr/share/nginx/html

# Expose port 80 to allow external access
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
