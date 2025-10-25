<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'db.php';

echo "<h2>Задание 2: Удаление самой лёгкой детали</h2>";

try {
    if (empty($_POST['jtown'])) {
        throw new Exception("⚠️ Город изделия не указан.");
    }
    $jtown = trim($_POST['jtown']);
    if (strlen($jtown) < 2) {
        throw new Exception("⚠️ Название города слишком короткое.");
    }

    $dbconn = getDbConnection();

    $sql_find = "
        SELECT p.n_det, p.ves
        FROM p
        WHERE p.n_det IN (
            SELECT DISTINCT spj.n_det
            FROM spj
            JOIN j ON spj.n_izd = j.n_izd
            WHERE j.town = '" . pg_escape_string($dbconn, $jtown) . "'
        )
        ORDER BY p.ves ASC
        LIMIT 1
    ";

    $res = pg_query($dbconn, $sql_find);

    if (!$res) {
        throw new Exception("❌ Ошибка при поиске детали: " . pg_last_error($dbconn));
    }

    if (pg_num_rows($res) === 0) {
        echo "<div style='color: orange; padding: 10px; border: 1px solid #ffe0b2; background: #fff8e1; border-radius: 4px;'>";
        echo "ℹ️ Для изделий из города <strong>" . htmlspecialchars($jtown) . "</strong> не найдено ни одной детали в схеме <code>pmib2309</code>.";
        echo "</div>";
    } else {
        $row = pg_fetch_assoc($res);
        $n_det = $row['n_det'];
        $ves = $row['ves'];

        $del_spj = pg_query($dbconn, "DELETE FROM spj WHERE n_det = '" . pg_escape_string($dbconn, $n_det) . "'");
        if (!$del_spj) {
            throw new Exception("❌ Не удалось удалить связи поставок для детали $n_det: " . pg_last_error($dbconn));
        }

        $del_p = pg_query($dbconn, "DELETE FROM p WHERE n_det = '" . pg_escape_string($dbconn, $n_det) . "'");
        if (!$del_p) {
            throw new Exception("❌ Не удалось удалить деталь $n_det из таблицы p: " . pg_last_error($dbconn));
        }

        echo "<div style='color: green; padding: 10px; border: 1px solid #c8e6c9; background: #f1f8e9; border-radius: 4px;'>";
        echo "✅ Удалена деталь <code>$n_det</code> (вес: $ves) для изделий из города <strong>" . htmlspecialchars($jtown) . "</strong>.";
        echo "</div>";
    }

} catch (Exception $e) {
    echo "<div style='color: red; padding: 10px; border: 1px solid #ffcccc; background: #fff0f0; border-radius: 4px;'>";
    echo "<strong>Ошибка:</strong> " . htmlspecialchars($e->getMessage());
    echo "</div>";
}

if (isset($dbconn)) pg_close($dbconn);
echo '<br><br><a href="lab.php">← Вернуться к выбору заданий</a>';
?>