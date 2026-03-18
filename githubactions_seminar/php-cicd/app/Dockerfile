# 1. ビルド引数を受け取るARGを定義
ARG ACCOUNT_ID=default
ARG REGION=ap-northeast-1
ARG ECR_REPO_PHP_Apache=default

# 2. FROMでARGを使用してURIを構成
FROM ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_PHP_Apache}:8.1-apache

# 3. 必要なPHP拡張をインストール
RUN docker-php-ext-install mysqli pdo pdo_mysql

# 4. 作業ディレクトリを設定（相対パスを簡略化）
WORKDIR /var/www/html

# 5. プロジェクト全体をコピー
COPY . /var/www/html/

# 6. 権限調整（任意：ファイルアップロードや書き込みをするなら必要）
RUN chown -R www-data:www-data /var/www/html

