FROM node:22-slim AS builder 

WORKDIR /app 

COPY package*.json /app 

RUN npm ci 

COPY . . 

# defining the env for apiUrl in db.js, it will be accessed durning container build time. 
# ARG makes it settable from docker-compose's build.args
ARG REACT_APP_BACKEND_URL

# ENV expose it to the 'npm run build' process
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

RUN npm run build 
# this will produce the build files 

FROM nginx:alpine AS serve 

WORKDIR /app 

COPY --from=builder /app/build /usr/share/nginx/html 

EXPOSE 80 

CMD ["nginx", "-g", "daemon off;"]

