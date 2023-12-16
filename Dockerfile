FROM node:18-alpine AS development
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json ./
COPY yarn.lock ./
COPY ./prisma ./prisma/
RUN yarn install --frozen-lockfile
RUN npx prisma generate

FROM node:18-alpine AS testing
WORKDIR /app
COPY --from=development /app/node_modules ./node_modules
COPY . .

ENV NODE_ENV testing
ENV NEXT_TELEMETRY_DISABLED 1

RUN yarn build && yarn install --production

FROM node:18-alpine AS production
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 usergroup
RUN adduser --system --uid 1001 userone

COPY --from=testing --chown=userone:usergroup /app/dist ./dist/
COPY --from=testing /app/node_modules ./node_modules/
COPY --from=testing /app/package.json ./
COPY --from=testing /app/yarn.lock ./
COPY --from=testing /app/.env ./

USER userone

EXPOSE 3000

ENV PORT 3000

CMD ["yarn", "prod"]