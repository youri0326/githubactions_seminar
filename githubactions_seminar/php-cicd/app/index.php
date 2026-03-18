<?php
$host = getenv('DB_HOST'); // タスク定義の環境変数から値を取得
$db   = getenv('DB_NAME');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    // 出力結果
    echo "DB接続成功！<br>";
    //継続的デプロイを確認するための出力
    
    // データ取得
    $stmt = $pdo->query("SELECT * FROM users");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo $row['id'] . ": " . $row['name'] . "<br>";
    }
} catch (PDOException $e) {
    echo "DB接続失敗: " . $e->getMessage();
}
