#!/bin/bash
# ==========================================================
# 第3章：演習の準備
# ==========================================================
# ------------------------------
# 3-5. AWS CLIのインストール
# ------------------------------
# ①AWS CLIのインストール
#公式サイトからインストーラーのダウンロード
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

#解凍用のzipコマンドのインストール
sudo apt install unzip

#zipファイルの解凍
unzip awscliv2.zip

#CLIのインストール
sudo ./aws/install

#インストールの確認
aws --version

#④AWS CLIでAWSへログイン
aws configure

# ==========================================================
# アクセスキーの入力を求められるので、先ほどコピーした内容を元に次の通りに入力ください。
# AWS Access Key ID [None]:アクセスキーIDを入力
# AWS Secret Access Key [None]:シークレットアクセスキーを入力
# Default region name [None]: 「ap-northeast-1」
# Default output format [None]: 「json」
# ==========================================================
# ------------------------------
# 3-6. ECRの環境準備
# ------------------------------
# ------------------------------
# ⓪事前準備
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="（ここに苗字を入力してください）" 
# 日付（例: 1019）
DATE="（ここに本日の月日を入力してください）" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

#アカウントIDの指定
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

#作成するECR名の登録
PHP_REPO_NAME="ecr-php-${USER_NAME_DATE}"
PMA_REPO_NAME="ecr-phpmyadmin-${USER_NAME_DATE}" 
PHP_APACHE_REPO_NAME="ecr-php-apache-${USER_NAME_DATE}"

# ECRへのログイン
aws ecr get-login-password --region ${REGION} | \
docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

#作業ディレクトリへ移動
cd /mnt/c/githubactions_seminar

# ------------------------------
# ① ECRの作成
# ------------------------------
# PHP専用のECRを作成する
aws ecr create-repository --repository-name ${PHP_REPO_NAME} --region ${REGION}

# phpMyAdmin専用のECRを作成する
aws ecr create-repository --repository-name ${PMA_REPO_NAME} --region ${REGION}

# PHP-Apache専用のECRを作成する
aws ecr create-repository --repository-name ${PHP_APACHE_REPO_NAME} --region ${REGION}


# ------------------------------
# ② Dockerイメージのプル
# ------------------------------
#phpMyAdminイメージのプル
docker pull phpmyadmin/phpmyadmin:5.2.1

#PHP-Apacheイメージのプル
docker pull php:8.1-apache

# ------------------------------
# ③ phpMyAdminイメージのプッシュ
# ------------------------------
# phpMyAminイメージをECRへタグ付け
docker tag phpmyadmin/phpmyadmin:5.2.1 ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PMA_REPO_NAME}:5.2.1

# phpMyAdminイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PMA_REPO_NAME}:5.2.1

# ==========================================================
# ④ PHP-Apacheイメージのプッシュ (リポジトリ名: ecr-php-apache...)
# ==========================================================
# PHP-ApacheイメージをECRへタグ付け
docker tag php:8.1-apache ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PHP_APACHE_REPO_NAME}:8.1-apache

# PHP-Apacheイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PHP_APACHE_REPO_NAME}:8.1-apache


# ==========================================================
# ⑤ PHPイメージの作成
# ==========================================================
docker build --build-arg ACCOUNT_ID=${ACCOUNT_ID} --build-arg REGION=${REGION} --build-arg ECR_REPO_PHP_Apache=${PHP_APACHE_REPO_NAME} -t ${PHP_REPO_NAME}:latest ./php-cicd/app

# ==========================================================
# ⑥ PHPイメージのプッシュ
# ==========================================================
#PHPイメージをECRへタグ付け
docker tag ${PHP_REPO_NAME}:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PHP_REPO_NAME}:latest

#PHPイメージのプッシュ
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PHP_REPO_NAME}:latest







# ==========================================================
# 第4章
# ==========================================================
# ------------------------------
# 4-1. Gitのインストール
# ------------------------------
#① Gitのインストール状況の確認
git --version

#② Gitのインストール
#パッケージ管理システムの更新
sudo apt update

#Gitのインストール
sudo apt install git

#③ Gitユーザー情報の初期設定
#メールアドレスの設定
#""内には、ご自身のGitHubで使用するメールアドレスを設定ください。
git config --global user.email "<GitHub上のメールアドレス>"

#名前の設定
#""内には、ご自身のGitHubでのユーザー名を設定ください。
git config --global user.name "<GitHubでのユーザー名>"

# ------------------------------
# 4-2. ローカル・GitHub間のSSH接続
# ------------------------------
# ① 秘密鍵・公開鍵の生成
#「~./ssh」ディレクトリの作成と移動
mkdir ~/.ssh

#「~./ssh」ディレクトリへの移動
cd ~/.ssh

#秘密鍵・公開鍵の作成
# ※ パスフレーズ入力を求められますが無視してエンター3回
ssh-keygen -t rsa

#秘密鍵・公開鍵の作成状況を確認する
ls

#公開鍵の内容を確認する
# ※後ほど利用するので出力内容をコピーする
cat ~/.ssh/id_rsa.pub

# ② GitHubへの公開鍵の設定
#「https://github.com/settings/ssh/new」アクセスし、コピーした内容を貼り付け「ADD SSH KEYをクリック」

# ==========================================================
# 第5章：CloudFormationでインフラ環境準備
# ==========================================================
# ------------------------------
# ① 環境変数の設定
# ------------------------------
# ユーザー名を変数に格納
# 氏名（例: Yamada）
USER_NAME="（ここに苗字を入力してください）" 
# 日付（例: 1019）
DATE="（ここに本日の月日を入力してください）" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

#リージョンを変数に格納 （※デプロイするリージョンに合わせて修正してください）
REGION="ap-northeast-1" 

GITHUB_USER="<GITHUB_USER>"

# ------------------------------
# ② 作業ディレクトリの移動
# ------------------------------
cd /mnt/c/githubactions_seminar

# ------------------------------
# ③ CloudFormationでインフラ環境構築
# ------------------------------
aws cloudformation deploy \
  --template-file cicd-seminar-infra.yaml \
  --stack-name cicd-${USER_NAME_DATE} \
  --parameter-overrides UserNameDate=${USER_NAME_DATE} GithubUser=${GITHUB_USER} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ${REGION}


# ------------------------------
# 第6章：RollingデプロイでphpMyAdminのCI/CD構築
# ------------------------------
# ------------------------------
# 6-0. 環境に合わせた文字列の置換
# ------------------------------

# ------------------------------
# ① 環境変数の設定
# ------------------------------
#以下、これまで設定したものと同じ値を設定ください。
# 氏名（例: Yamada）
export USER_NAME="（ここに苗字を入力してください）" 
# 日付（例: 1019）
export DATE="（ここに本日の月日を入力してください）" 
#リージョンの設定
export REGION="ap-northeast-1" 

#GITHUBユーザーの設定
export GITHUB_USER="（ここにGITHUBのユーザー名を入力してください）"

# ------------------------------
# ② 置換用の実行ファイルの実行
# ------------------------------
#作業ディレクトリへ移動
cd /mnt/c/githubactions_seminar

#実行ファイルへ実行権限の付与
chmod +x replace_placeholders.sh

#実行ファイルの実行
./replace_placeholders.sh

# ------------------------------
# 6-1. GitHubとローカルの連携
# ------------------------------
#⓪ 環境変数の設定
GITHUB_USER="<GITHUB_USER>"

#① phpMyAdminリポジトリをローカル環境にクローン
# phpMyAdmin用のディレクトリの作成
mkdir -p /mnt/c/githubactions_seminar_phpmyadmin

# phpMyAdmin用のディレクトリに移動
cd /mnt/c/githubactions_seminar_phpmyadmin

# phpMyAdminリポジトリをローカル環境にクローン
echo "# githubactions_seminar_phpmyadmin" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:${GITHUB_USER}/githubactions_seminar_phpmyadmin.git
git push -u origin main

#② CI/CD関連のファイルのコピー
cp -r /mnt/c/githubactions_seminar/phpmyadmin-cicd/. /mnt/c/githubactions_seminar_phpmyadmin

#③ GitHubへプッシュ
git add .
git commit -m "Add initial project files for CI/CD setup"
git push origin main

# ------------------------------
# 6-2. Workflow再起動
# ------------------------------
#ブラウザ上で行う

# ------------------------------
# 6-3. 動作確認
# -----------------------------
#① GitHubActionsの稼働状況を確認する
#  ブラウザ上で、GitHub Actions Successを確認する

#② ECSの稼働状況の確認
#環境変数の設定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 

# ECSタスクのARNの取得
TASK_ARN=$(aws ecs list-tasks \
    --cluster ecs-cluster-${USER_NAME_DATE} \
    --service-name phpmyadmin-service-${USER_NAME_DATE} \
    --region ap-northeast-1 \
    --query 'taskArns' \
    --output text)

# ECSの稼働状況の確認
aws ecs describe-tasks \
    --cluster ecs-cluster-${USER_NAME_DATE} \
    --tasks $TASK_ARN \
    --region ap-northeast-1 \
    --query 'tasks[0].containers[0].[name, lastStatus, taskDefinitionArn]' \
    --output table

#③ ブラウザからアクセス
# クラスター名、サービス名の設定
CLUSTER_NAME="ecs-cluster-${USER_NAME_DATE}"
SERVICE_NAME="phpmyadmin-service-${USER_NAME_DATE}"

#IPアドレスの取得
PAM_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids $(aws ecs describe-tasks \
    --cluster "${CLUSTER_NAME}" \
    --tasks $(aws ecs list-tasks \
      --cluster "${CLUSTER_NAME}" \
      --service-name "${SERVICE_NAME}" \
      --query "taskArns[0]" \
      --output text) \
    --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" \
    --output text) \
  --query "NetworkInterfaces[0].Association.PublicIp" \
  --output text)

# URL(IPアドレス)の確認
URL="http://"${PAM_IP}
echo "URLにアクセス:"${URL}


# ------------------------------
# 第7章：Blue/GreenデプロイでPHPのCI/CD構築
# ------------------------------

# ------------------------------
# 7-1. CodeDeployの準備 
# ------------------------------
#① 環境変数の設定
#ユーザ名の指定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 
#リージョンの指定
REGION=ap-northeast-1

# ② 作業ディレクトリの移動
cd /mnt/c/githubactions_seminar

#③ CodeDeployアプリケーションの作成
aws deploy create-application \
  --application-name cicd-aws-codedeploy-php-${USER_NAME_DATE} \
  --compute-platform ECS \
  --region ${REGION}


#③ CodeDeploy Groupの作成
aws deploy create-deployment-group \
  --cli-input-json file://php-cicd/CodeDeploy/tg-pair.json \
  --region ${REGION}


# ------------------------------
# 7-2. GitHubとローカルの連携
# ------------------------------
#⓪ 環境変数の設定 
GITHUB_USER="<GITHUB_USER>"

#① PHPリポジトリをローカル環境にクローン
# PHP用のディレクトリの作成
mkdir -p /mnt/c/githubactions_seminar_php
#PHP用のディレクトリに移動
cd /mnt/c/githubactions_seminar_php

#PHPリポジトリをローカル環境にクローン
echo "# githubactions_seminar_php" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:${GITHUB_USER}/githubactions_seminar_php.git
git push -u origin main


#② CI/CD関連のファイルのコピー
#文字コードをLFに固定する
sudo apt update
sudo apt install dos2unix
dos2unix /mnt/c/githubactions_seminar/php-cicd/CodeDeploy/appspec.yml

#CI/CD関連のファイルのコピー
cp -r /mnt/c/githubactions_seminar/php-cicd/. /mnt/c/githubactions_seminar_php

# ③ GitHubへプッシュ
git add .
git commit -m "Add initial project files for CI/CD setup"
git push origin main


# ------------------------------
# 7-3. Workflow再起動と動作確認
# ------------------------------
# ブラウザ上で行う

# ------------------------------
# 7-4. 動作確認
# ------------------------------
#① Workflowの状況確認
#  ブラウザ上で、GitHub Actions Successを確認する

#② CI/CDの稼働状況の確認
#②-1 共通の環境変数の設定
#ユーザ名の指定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 
#リージョンの指定
REGION=ap-northeast-1

#②-2 デプロイの実行状況の確認
#デプロイのIDの確認
DEPLOY_ID=$(aws deploy list-deployments \
    --application-name cicd-aws-codedeploy-php-${USER_NAME_DATE} \
    --deployment-group-name cicd-aws-codedeploy-php-group \
    --query 'deployments[0]' \
    --output text)

#デプロイの実行状況の確認
aws deploy get-deployment \
    --deployment-id ${DEPLOY_ID} \
    --query '{Status:deploymentInfo.status,TrafficShiftCompleted:deploymentInfo.completeTime}' \
    --output table

#②-3 ECSの稼働状況の確認
TASK_ARN=$(aws ecs list-tasks \
    --cluster ecs-cluster-${USER_NAME_DATE} \
    --service-name php-service-${USER_NAME_DATE} \
    --region ap-northeast-1 \
    --query 'taskArns' \
    --output text)
    
aws ecs describe-tasks \
    --cluster ecs-cluster-${USER_NAME_DATE} \
    --tasks $TASK_ARN \
    --region ap-northeast-1 \
    --query 'tasks[0].containers[0].[name, lastStatus, taskDefinitionArn]' \
    --output table

#②-4 ロードバランサーの状況確認
# BlueターゲットグループARNを取得
BLUE_TG_ARN=$(aws elbv2 describe-target-groups \
  --names php-blue-tg-${USER_NAME_DATE} \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# GreenターゲットグループARNを取得
GRENN_TG_ARN=$(aws elbv2 describe-target-groups \
  --names php-green-tg-${USER_NAME_DATE} \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

#Blueターゲットグループのヘルスチェックをする
aws elbv2 describe-target-health \
    --target-group-arn ${BLUE_TG_ARN} \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
    --output table

#Greenターゲットグループのヘルスチェックをする
aws elbv2 describe-target-health \
    --target-group-arn ${GRENN_TG_ARN} \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
    --output table

# ③ ブラウザからの動作確認
#ロードバランサーのDNS名の取得
php_alb_dns=$(aws elbv2 describe-load-balancers \
    --names alb-${USER_NAME_DATE} \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

#アクセスするURLの取得
URL="http://"${php_alb_dns}

#URLの表示
echo "URLにアクセス:"${URL}

#④ 継続的デプロイの確認
#④-1 index.phpの修正 12行目に「echo "継続的デプロイの成功！<br>";」を追記-

#④-2 GITHUBへのプッシュ
cp -r /mnt/c/githubactions_seminar/php-cicd/. /mnt/c/githubactions_seminar_php
git add .
git commit -m "Add initial project files for CI/CD setup"
git push origin main

#④-3 GitHubActionsの成功を確認する
#ブラウザ上で、GitHub Actions Successを確認する

#④-4 動作確認
#ロードバランサーのDNS名の取得
php_alb_dns=$(aws elbv2 describe-load-balancers \
    --names alb-${USER_NAME_DATE} \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

#アクセスするURLの取得
URL="http://"${php_alb_dns}

#URLの表示
echo "URLにアクセス:"${URL}

# ------------------------------
# 第8章：リリースの削除
# ------------------------------
# ------------------------------
# 8-1. 共通の環境変数の設定
# ------------------------------
#ユーザ名の指定
# 氏名（例: TaroYamada ※半角英字）
USER_NAME="<氏名>" 
# 日付（例: 1019）
DATE="<日付>" 
USER_NAME_DATE="${USER_NAME}-${DATE}" 
#リージョンの指定
REGION=ap-northeast-1

# ------------------------------
# 8-2. CodeDeployの削除
# ------------------------------
# グループ名を取得
DG_NAME="cicd-aws-codedeploy-php-group"
APP_NAME="cicd-aws-codedeploy-php-${USER_NAME_DATE}"

#CodeDeployグループの削除
aws deploy delete-deployment-group \
  --application-name ${APP_NAME} \
  --deployment-group-name ${DG_NAME} \
  --region ${REGION} || echo "Deployment group not found"

#CodeDeployアプリケーションの削除
aws deploy delete-application \
  --application-name ${APP_NAME} \
  --region ${REGION} || echo "CodeDeploy application not found"

# ------------------------------
# 8-3. ECS、ECRの削除
# ------------------------------
#① ECSの削除
#(第6章で使用した) phpMyAdmin用のECSサービスの削除
aws ecs delete-service \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service phpmyadmin-service-${USER_NAME_DATE} \
  --force \
  --region ${REGION}

#(第7章で使用した) PHP用のECSサービスの削除
aws ecs delete-service \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --service php-service-${USER_NAME_DATE} \
  --force \
  --region ${REGION}

#ECSクラスターの削除
aws ecs delete-cluster \
  --cluster ecs-cluster-${USER_NAME_DATE} \
  --region ${REGION} 



#② ECRの削除
#phpMyAdmin用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-phpmyadmin-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-phpmyadmin-${USER_NAME_DATE} not found"

#PHP用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-php-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-php-${USER_NAME_DATE} not found"

#PHP-Apache用のECRの削除
aws ecr delete-repository \
  --repository-name ecr-php-apache-${USER_NAME_DATE} \
  --force \
  --region ${REGION} || echo "ECR ecr-php-apache-${USER_NAME_DATE} not found"

# ------------------------------
# 8-4. ALB / Target Groupの削除
# ------------------------------
# ① ALB(ロードバランサー)の削除
# ロードバランサー名の取得
ALB_NAME="alb-${USER_NAME_DATE}"

# ロードバランサーARNの取得
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names "${ALB_NAME}" \
  --query "LoadBalancers[0].LoadBalancerArn" \
  --output text --region ${REGION} 2>/dev/null || true)

#ロードバランサーの削除
aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" --region ${REGION}

# ② ターゲットグループの削除
#Blue ターゲットグループ名の取得
TG_ARN_BLUE=$(aws elbv2 describe-target-groups \
  --names "php-blue-tg-${USER_NAME_DATE}" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text 2>/dev/null || true)

#Blueターゲットグループの削除
aws elbv2 delete-target-group --target-group-arn "${TG_ARN_BLUE}" --region ${REGION}

#Green ターゲットグループ名の取得
TG_ARN_GREEN=$(aws elbv2 describe-target-groups \
  --names "php-green-tg-${USER_NAME_DATE}" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text 2>/dev/null || true)

#Greenターゲットグループの削除
aws elbv2 delete-target-group --target-group-arn "${TG_ARN_GREEN}" --region ${REGION}



# ------------------------------
# 8-5. CloudFormationスタックの削除
# ------------------------------
aws cloudformation delete-stack \
  --stack-name cicd-${USER_NAME_DATE} \
  --region ${REGION}


