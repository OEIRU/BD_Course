<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'db.php';

echo "<h2>Задание 1: Добавление поставщика</h2>";

try {
    if (empty($_POST['sname'])) {
        throw new Exception("⚠️ Имя поставщика не указано.");
    }
    $sname = trim($_POST['sname']);
    if (strlen($sname) < 2) {
        throw new Exception("⚠️ Имя поставщика слишком короткое.");
    }

    $dbconn = getDbConnection();

    $sql1 = "
        SELECT s.n_post, s.town, s.reiting
        FROM s
        LEFT JOIN spj ON s.n_post = spj.n_post
        GROUP BY s.n_post, s.town, s.reiting
        ORDER BY COUNT(spj.n_post) ASC
        LIMIT 1
    ";
    $res1 = pg_query($dbconn, $sql1);

    if (!$res1) {
        throw new Exception("❌ Ошибка при поиске поставщика-образца: " . pg_last_error($dbconn));
    }

    if (pg_num_rows($res1) === 0) {
        throw new Exception("⚠️ В схеме pmib2309 нет ни одного поставщика в таблице 's'.");
    }

    $row1 = pg_fetch_assoc($res1);
    $town = pg_escape_string($dbconn, $row1['town']);
    $reiting = (int)$row1['reiting'];

    // Генерация уникального кода
    $new_n_post = 'S' . strtoupper(substr(md5(uniqid()), 0, 4));

    $insert_sql = "
        INSERT INTO s (n_post, name, reiting, town)
        VALUES ('" . pg_escape_string($dbconn, $new_n_post) . "', 
                '" . pg_escape_string($dbconn, $sname) . "', 
                $reiting, 
                '$town')
    ";
    $ins = pg_query($dbconn, $insert_sql);

    if (!$ins) {
        throw new Exception("❌ Не удалось добавить поставщика: " . pg_last_error($dbconn));
    }

    echo "✅ Поставщик <strong>" . htmlspecialchars($sname) . "</strong> (код: <code>$new_n_post</code>) успешно добавлен в город <em>" . htmlspecialchars($town) . "</em> с рейтингом $reiting.";

} catch (Exception $e) {
    echo "<div style='color: red; padding: 10px; border: 1px solid #ffcccc; background: #fff0f0; border-radius: 4px;'>";
    echo "<strong>Ошибка:</strong> " . htmlspecialchars($e->getMessage());
    echo "</div>";
}

if (isset($dbconn)) pg_close($dbconn);
echo '<br><br><a href="lab.php">← Вернуться к выбору заданий</a>';
?>