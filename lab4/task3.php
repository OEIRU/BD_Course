<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'db.php';

echo "<h2>Задание 3: Статистика по поставкам</h2>";

try {
    $threshold = isset($_POST['threshold']) ? (int)$_POST['threshold'] : 100;
    if ($threshold < 0) $threshold = 0;

    $dbconn = getDbConnection();

    $sql = "
        SELECT 
            s.n_post,
            COUNT(CASE WHEN spj.kol > \$1 THEN 1 END) AS cnt
        FROM s
        LEFT JOIN spj ON s.n_post = spj.n_post
        GROUP BY s.n_post
        ORDER BY s.n_post
    ";

    $res = pg_query_params($dbconn, $sql, [$threshold]);

    if (!$res) {
        throw new Exception("❌ Ошибка при получении статистики: " . pg_last_error($dbconn));
    }

    echo "<p>📊 Порог объёма поставки: <strong>$threshold</strong></p>";

    if (pg_num_rows($res) === 0) {
        echo "<div style='color: orange; padding: 10px; border: 1px solid #ffe0b2; background: #fff8e1; border-radius: 4px;'>";
        echo "ℹ️ В схеме <code>pmib2309</code> нет поставщиков в таблице 's'.";
        echo "</div>";
    } else {
        echo "<ul style='background: #f5f5f5; padding: 15px; border-radius: 6px; max-width: 500px;'>";
        while ($row = pg_fetch_assoc($res)) {
            echo "<li><strong>Поставщик " . htmlspecialchars($row['n_post']) . ":</strong> " . (int)$row['cnt'] . " поставок</li>";
        }
        echo "</ul>";
    }

} catch (Exception $e) {
    echo "<div style='color: red; padding: 10px; border: 1px solid #ffcccc; background: #fff0f0; border-radius: 4px;'>";
    echo "<strong>Ошибка:</strong> " . htmlspecialchars($e->getMessage());
    echo "</div>";
}

if (isset($dbconn)) pg_close($dbconn);
echo '<br><br><a href="lab.php">← Вернуться к выбору заданий</a>';
?>