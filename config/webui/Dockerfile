# Angular build için Node imajı
FROM node:18-alpine AS builder

# Uygulama dizini
WORKDIR /app

# Tüm dosyaları kopyala
COPY . .

# Angular CLI yükle
RUN npm install -g @angular/cli

# Bağımlılıkları yükle
RUN npm install

# Prod build al (outputPath angular.json'dan alınacak)
RUN ng build --configuration=production

# Nginx ile sunmak için ikinci aşama
FROM nginx:alpine

# Angular çıktısını Nginx dizinine kopyala
COPY --from=builder /app/dist/BizimNetWebUI-V1 /usr/share/nginx/html

# env.js dosyasını da ekle (eğer gerekiyorsa)
COPY src/assets/env.js /usr/share/nginx/html/assets/env.js

# Nginx için port
EXPOSE 80

# Nginx çalıştır
CMD ["nginx", "-g", "daemon off;"]

