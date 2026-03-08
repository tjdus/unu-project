#!/bin/bash

# SSL 인증서 초기 발급 스크립트

# 설정 변수 (여기를 수정하세요!)
DOMAIN="cnu-nu.com"
EMAIL="dusml0277@gmail.com"
STAGING=0  # 테스트시 1로 변경

# 도메인/이메일 확인
if [ "$DOMAIN" = "your-domain.com" ] || [ "$EMAIL" = "your-email@example.com" ]; then
    echo "[오류] DOMAIN과 EMAIL을 실제 값으로 변경하세요!"
    exit 1
fi

echo "도메인: ${DOMAIN}, 이메일: ${EMAIL}"

# 디렉토리 생성
mkdir -p nginx/certbot/conf nginx/certbot/www

# 초기 nginx 설정 적용
cp nginx/nginx.conf nginx/nginx-ssl.conf.backup
cp nginx/nginx-init.conf nginx/nginx.conf

# 도메인 설정 (Linux/macOS 호환)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/your-domain.com/${DOMAIN}/g" nginx/nginx-ssl.conf.backup
else
    sed -i "s/your-domain.com/${DOMAIN}/g" nginx/nginx-ssl.conf.backup
fi

# nginx 시작
docker compose up -d nginx
sleep 5

# 인증서 발급
staging_arg=""
[ $STAGING -eq 1 ] && staging_arg="--staging"

docker compose run --rm certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email ${EMAIL} --agree-tos --no-eff-email \
    ${staging_arg} -d ${DOMAIN}

if [ $? -eq 0 ]; then
    cp nginx/nginx-ssl.conf.backup nginx/nginx.conf
    rm -f nginx/nginx-ssl.conf.backup
    docker compose restart nginx
    echo "완료! https://${DOMAIN} 으로 접속하세요."
else
    echo "인증서 발급 실패. 도메인 DNS 설정을 확인하세요."
    cp nginx/nginx-ssl.conf.backup nginx/nginx.conf 2>/dev/null
    exit 1
fi

