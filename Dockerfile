# this is even optimized by remove unwanted cache using multi stage build

# ==========================
# Stage 1: Build dependencies
# ==========================
FROM node:20-alpine3.19 AS builder

WORKDIR /opt/server

# Copy dependency file & install ONLY production dependencies
COPY package.json .
RUN npm install --omit=dev

# Copy application source
COPY server.js .


# ==========================
# Stage 2: Runtime image
# ==========================
FROM node:20-alpine3.19

# Create non-root system user
RUN addgroup -S roboshop && \
    adduser -S -G roboshop roboshop

WORKDIR /opt/server
USER roboshop

# Environment variables (same as original)
ENV MONGO=true \
    MONGO_URL=mongodb://mongodb:27017/catalogue

# Copy built app from builder stage
COPY --from=builder --chown=roboshop:roboshop /opt/server /opt/server

EXPOSE 8080

CMD ["node", "server.js"]








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

