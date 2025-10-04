<?php
// Устанавливаем кодировку
header('Content-Type: text/html; charset=utf-8');

// Подключаемся к БД
$dbconn = pg_connect("host=bbbb.bbb.bbbb.ru port=5432 dbname=students user=pmi-bxxyy password=111111");
// надо бы в отдельный .env файлик для безопасности :)
if (!$dbconn) {
    die("❌ Ошибка подключения к базе данных.");
}

// Получаем данные из формы
$sname = pg_escape_string($_POST['sname']);
$jtown = pg_escape_string($_POST['jtown']);
$threshold = (int)$_POST['threshold'];

echo "<h2>Результаты выполнения заданий</h2>";

// === Задание 1: Добавить поставщика ===
echo "<h3>1. Добавление поставщика...</h3>";
$res1 = pg_query($dbconn, "
    SELECT s.n_post, s.town, s.reiting
    FROM s
    LEFT JOIN spj ON s.n_post = spj.n_post
    GROUP BY s.n_post, s.town, s.reiting
    ORDER BY COUNT(spj.n_post) ASC
    LIMIT 1
");

if ($row1 = pg_fetch_assoc($res1)) {
    // Генерируем уникальный код поставщика (простой способ)
    $new_n_post = 'S' . substr(time(), -4); // например: S1234

    $ins = pg_query($dbconn, "
        INSERT INTO s (n_post, name, reiting, town)
        VALUES ('$new_n_post', '$sname', {$row1['reiting']}, '{$row1['town']}')
    ");
    if ($ins) {
        echo "✅ Поставщик '$sname' (код: $new_n_post) добавлен с городом '{$row1['town']}' и рейтингом {$row1['reiting']}.<br>";
    } else {
        echo "❌ Ошибка вставки: " . pg_last_error($dbconn) . "<br>";
    }
} else {
    echo "⚠️ Не удалось найти поставщика для копирования данных.<br>";
}

// === Задание 2: Удалить самую лёгкую деталь ===
echo "<h3>2. Удаление самой лёгкой детали для изделий из города '$jtown'...</h3>";

$find_det = pg_query($dbconn, "
    SELECT p.n_det
    FROM p
    WHERE p.n_det IN (
        SELECT DISTINCT spj.n_det
        FROM spj
        JOIN j ON spj.n_izd = j.n_izd
        WHERE j.town = '$jtown'
    )
    ORDER BY p.ves ASC
    LIMIT 1
");

if ($det_row = pg_fetch_assoc($find_det)) {
    $n_det = $det_row['n_det'];
    pg_query($dbconn, "DELETE FROM spj WHERE n_det = '$n_det'");
    pg_query($dbconn, "DELETE FROM p WHERE n_det = '$n_det'");
    echo "✅ Деталь с кодом '$n_det' удалена.<br>";
} else {
    echo "⚠️ Не найдено деталей для изделий из города '$jtown'.<br>";
}

// === Задание 3: Статистика по поставкам ===
echo "<h3>3. Число поставок с объёмом > $threshold:</h3>";
$res3 = pg_query_params($dbconn, "
    SELECT 
        s.n_post,
        COUNT(CASE WHEN spj.kol > \$1 THEN 1 END) AS cnt
    FROM s
    LEFT JOIN spj ON s.n_post = spj.n_post
    GROUP BY s.n_post
    ORDER BY s.n_post
", [$threshold]);

echo "<ul>";
while ($row3 = pg_fetch_assoc($res3)) {
    echo "<li>Поставщик {$row3['n_post']}: {$row3['cnt']} поставок</li>";
}
echo "</ul>";

// Закрываем соединение
pg_close($dbconn);

// Кнопка "Назад"
echo '<br><a href="lab.php">← Вернуться к форме</a>';
?>
