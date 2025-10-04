<?php
function getDbConnection() {
    $conn = pg_connect("host=bbbb.bbb.bbbb.ru port=5432 dbname=students user=pmi-b2309 password=brepsi");
    if (!$conn) {
        throw new Exception("❌ Не удалось подключиться к базе данных.");
    }
    // Указываем схему по умолчанию
    $set_path = pg_query($conn, "SET search_path TO pmib2309, public;");
    if (!$set_path) {
        throw new Exception("❌ Не удалось установить схему " . pg_last_error($conn));
    }
    return $conn;
}
?>
