FROM node:22-alpine AS builder
WORKDIR /app
COPY web_react/package.json web_react/package-lock.json ./
RUN npm ci
COPY web_react/ ./
ENV VITE_API_BASE_URL=""
RUN npm run build
FROM nginx:1.28-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
