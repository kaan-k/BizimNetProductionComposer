#!/usr/bin/env bash
set -euo pipefail

# ========== RENKLER ==========
if command -v tput >/dev/null 2>&1; then
  GREEN="$(tput setaf 2)"; RED="$(tput setaf 1)"; CYAN="$(tput setaf 6)"; YELLOW="$(tput setaf 3)"; RESET="$(tput sgr0)"
else
  GREEN=""; RED=""; CYAN=""; YELLOW=""; RESET=""
fi

clear
cat <<'BIZIMNET'

                                                                                                                                                     
__________.__       .__          _______          __           ________  
\______   \__|______|__| _____   \      \   _____/  |_   ___  _\_____  \ 
 |    |  _/  \___   /  |/     \  /   |   \_/ __ \   __\  \  \/ //  ____/ 
 |    |   \  |/    /|  |  Y Y  \/    |    \  ___/|  |     \   //       \ 
 |______  /__/_____ \__|__|_|  /\____|__  /\___  >__|      \_/ \_______ \
        \/         \/        \/         \/     \/                      \/       

BIZIMNET

echo -e "${CYAN}BizimNet Basit Kurulum Aracı${RESET}"
echo
echo -e "${YELLOW}1) Kurulumu Başlat${RESET}"
echo -e "${YELLOW}2) Sunucuyu Aç${RESET}"
echo -e "${YELLOW}3) Çıkış${RESET}"
echo -e "${YELLOW}4) Database Yedeği Al${RESET}"
echo -e "${YELLOW}5) Database Yedeği Geri Yükle${RESET}"
echo
read -rp "Seçiminiz: " _choice
if [[ "${_choice}" == "3" ]]; then
  echo -e "${GREEN}Güle güle.${RESET}"; exit 0
fi

# ========== AYARLAR ==========
WORKDIR="/opt/bizimnet"
COMPOSE_FILE="${WORKDIR}/docker-compose.yml"
BACKUP_DIR="${WORKDIR}/backups"
WEBAPI_REPO="https://github.com/kaan-k/BizimNetWebAPI-V1.git"
WEBUI_REPO="https://github.com/kaan-k/BizimNetWebUI-V2.git"
WEBAPI_REF="main"
WEBUI_REF="main"

API_DIR="BizimNetWebAPI"
UI_DIR="BizimNetWebUI"


CFG_ENV_JS="${WORKDIR}/config/webui/env.js"
CFG_ANGULAR_JSON="${WORKDIR}/config/webui/angular.json"
CFG_NGINX_CONF="${WORKDIR}/config/webui/nginx.conf"
CFG_APPSETTINGS="${WORKDIR}/config/webapi/appsettings.json"

if [[ "${_choice}" == "2" ]]; then
  echo -e "${GREEN}[Start] docker compose up -d${RESET}"
  cd "$WORKDIR"
  if docker compose -f "$COMPOSE_FILE" up -d; then :; else docker-compose -f "$COMPOSE_FILE" up -d; fi
  echo -e "${CYAN}Sunucu ayağa kalktı.${RESET}"
  exit 0
fi

if [[ "${_choice}" == "4" ]]; then
  BACKUP_DIR="${WORKDIR}/backups"
  mkdir -p "$BACKUP_DIR"

  FILE="$BACKUP_DIR/mongo-$(date +%F_%H-%M).gz"

  echo -e "${GREEN}[Backup] Yedek alınıyor...${RESET}"
  docker exec arycrm-mongo mongodump --archive=/tmp/backup.gz --gzip
  docker cp arycrm-mongo:/tmp/backup.gz "$FILE"
  echo -e "${CYAN}Yedek tamamlandı: $FILE${RESET}"
  exit 0
fi

if [[ "${_choice}" == "5" ]]; then
  BACKUP_DIR="${WORKDIR}/backups"
  echo -e "${CYAN}Mevcut yedekler:${RESET}"
  ls -1 "$BACKUP_DIR"
  read -rp "Geri yüklenecek dosya adını girin: " RESTORE_FILE

  if [[ -f "$BACKUP_DIR/$RESTORE_FILE" ]]; then
    echo -e "${GREEN}[Restore] Geri yükleniyor...${RESET}"
    docker cp "$BACKUP_DIR/$RESTORE_FILE" arycrm-mongo:/tmp/restore.gz
    docker exec arycrm-mongo mongorestore --archive=/tmp/restore.gz --gzip --drop
    echo -e "${CYAN}Geri yükleme tamamlandı.${RESET}"
  else
    echo -e "${RED}Dosya bulunamadı: $RESTORE_FILE${RESET}"
  fi
  exit 0
fi

mkdir -p "$WORKDIR"; cd "$WORKDIR"

echo -e "${GREEN}[1/7] Repolar çekiliyor${RESET}"
rm -rf webapi_new webui_new
git clone --depth 1 --branch "$WEBAPI_REF" "$WEBAPI_REPO" webapi_new
git clone --depth 1 --branch "$WEBUI_REF"  "$WEBUI_REPO"  webui_new

echo -e "${GREEN}[2/7] Eski kaynak klasörleri temizleniyor${RESET}"
rm -rf "$API_DIR" "$UI_DIR"

echo -e "${GREEN}[3/7] Yeni klasörler adlandırılıyor${RESET}"
mv webapi_new "$API_DIR"
mv webui_new "$UI_DIR"

echo -e "${GREEN}[4/7] Config dosyaları kopyalanıyor (host → kaynak)${RESET}"

if [[ -f "$CFG_ENV_JS" ]]; then
  install -D "$CFG_ENV_JS" "$UI_DIR/src/assets/env.js"
else
  echo -e "${YELLOW}UYARI:${RESET} $CFG_ENV_JS yok, env.js dokunulmadı."
fi
# WebUI angular.json
if [[ -f "$CFG_ANGULAR_JSON" ]]; then
  install -D "$CFG_ANGULAR_JSON" "$UI_DIR/angular.json"
else
  echo -e "${YELLOW}UYARI:${RESET} $CFG_ANGULAR_JSON yok, repo'daki angular.json kullanılacak."
fi
if [[ -f "$CFG_NGINX_CONF" ]]; then
  install -D "$CFG_NGINX_CONF" "$UI_DIR/nginx.conf"
else
  echo -e "${YELLOW}UYARI:${RESET} $CFG_NGINX_CONF yok, default SPA nginx.conf üretilecek."
  cat > "$UI_DIR/nginx.conf" <<'EOF'
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;
  location / { try_files $uri $uri/ /index.html; }
}
EOF
fi
# WebAPI appsettings.json
if [[ -f "$CFG_APPSETTINGS" ]]; then
  install -D "$CFG_APPSETTINGS" "$API_DIR/BizimNetWebAPI/appsettings.json"
else
  echo -e "${YELLOW}UYARI:${RESET} $CFG_APPSETTINGS yok, appsettings.json dokunulmadı."
fi

echo -e "${GREEN}[5/7] WebUI prod build (host'ta Node gerekmez)${RESET}"
(
  cd "$UI_DIR"
  sudo docker run --rm -v "$PWD":/app -w /app node:22 \
    bash -lc "npm ci && npx ng build --configuration production --output-path=/app/dist"
)

echo -e "${GREEN}[6/7] Dockerfile'lar yoksa oluşturuluyor${RESET}"
if [[ ! -f "$UI_DIR/Dockerfile" ]]; then
  cat > "$UI_DIR/Dockerfile" <<'DOCKER'
FROM nginx:alpine
COPY ./dist/ /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
DOCKER
fi

if [[ ! -f "$API_DIR/Dockerfile" ]]; then
  cat > "$API_DIR/Dockerfile" <<'DOCKER'
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /out
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .
EXPOSE 5000
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
ENTRYPOINT ["dotnet","WebAPI.dll"]
DOCKER
fi

echo -e "${GREEN}[7/7] docker compose build --no-cache + up -d${RESET}"
if docker compose -f "$COMPOSE_FILE" build --no-cache; then
  docker compose -f "$COMPOSE_FILE" up -d
else
  docker-compose -f "$COMPOSE_FILE" build --no-cache
  docker-compose -f "$COMPOSE_FILE" up -d
fi

echo -e "${CYAN}Kurulum tamamlandı. SPA fallback aktif; Database volume'larına DOKUNULMADI.${RESET}"
