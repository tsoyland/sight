# syntax=docker/dockerfile:1

# ---- Frontend build ----
FROM node:22-alpine AS web
WORKDIR /src/web
COPY web/package.json web/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY web/ ./
RUN npm run build

# ---- Backend build ----
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS api
WORKDIR /src/api
COPY api/src/Sight.Api/Sight.Api.csproj src/Sight.Api/
RUN dotnet restore src/Sight.Api/Sight.Api.csproj
COPY api/src/ src/
ARG VERSION=0.0.0
RUN dotnet publish src/Sight.Api/Sight.Api.csproj -c Release -o /app --no-restore -p:Version=$VERSION

# ---- Runtime ----
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=api /app ./
COPY --from=web /src/web/dist ./wwwroot
# Scaleway Serverless Containers send traffic to $PORT (default 8080).
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
USER $APP_UID
ENTRYPOINT ["dotnet", "Sight.Api.dll"]
