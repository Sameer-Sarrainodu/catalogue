# this is even optimized by remove unwanted cache using multi stage build

FROM node:20-alpine3.19 AS builder
WORKDIR /opt/server
COPY package.json . 
COPY server.js .
RUN npm install

FROM node:20-alpine3.19
RUN addgroup -S roboshop && \
    adduser -S -D -H -h /opt/server -s /sbin/nologin -G roboshop roboshop
ENV MONGO=true \
    MONGO_URL=mongodb://mongodb:27017/catalogue
WORKDIR /opt/server
USER roboshop
COPY --from=builder /opt/server /opt/server
CMD [ "node","server.js" ]







# this is second version wiht optimized os using alpine
# FROM node:20-alpine3.21 
# RUN addgroup -S roboshop && \
#     adduser -S -D -H -h /opt/server -s /sbin/nologin -G roboshop roboshop
# WORKDIR /opt/server
# COPY package.json . 
# COPY server.js .
# RUN npm install
# ENV MONGO="true" \
#     MONGO_URL="mongodb://mongodb:27017/catalogue"
# USER roboshop
# CMD [ "node", "server.js" ]






# ---------------this is first basic one
# FROM node:20
# RUN groupadd -r roboshop && \
#     useradd -r -g roboshop -d /opt/server -s /usr/sbin/nologin roboshop
# WORKDIR /opt/server
# COPY package.json . 
# COPY server.js .
# RUN npm install
# ENV MONGO="true" \
#     MONGO_URL="mongodb://mongodb:27017/catalogue"
# USER roboshop
# CMD [ "node", "server.js" ]

