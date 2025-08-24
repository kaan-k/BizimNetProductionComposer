# .NET 8 runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

# .NET 8 SDK
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Tüm BizimNetWebAPI klasörünü tek seferde kopyala
COPY ./BizimNetWebAPI ./BizimNetWebAPI

# Restore
WORKDIR /src/BizimNetWebAPI/BizimNetWebAPI
RUN dotnet restore BizimNetWebAPI.csproj

# Publish
RUN dotnet publish BizimNetWebAPI.csproj -c Release -o /app/publish

# Final image
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "BizimNetWebAPI.dll"]

