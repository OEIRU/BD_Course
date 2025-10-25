<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Лабораторная работа по PHP</title>
</head>
<body>
    <h2>Выберите задание для выполнения</h2>

    <!-- Задание 1 -->
    <form method="post" action="task1.php">
        <p>
            <label>Имя нового поставщика: 
                <input type="text" name="sname" required>
            </label>
        </p>
        <button type="submit">✅ Выполнить задание 1 (добавить поставщика)</button>
    </form>
    <hr>

    <!-- Задание 2 -->
    <form method="post" action="task2.php">
        <p>
            <label>Город изделия (для удаления детали): 
                <input type="text" name="jtown" required>
            </label>
        </p>
        <button type="submit">🗑️ Выполнить задание 2 (удалить деталь)</button>
    </form>
    <hr>

    <!-- Задание 3 -->
    <form method="post" action="task3.php">
        <p>
            <label>Порог объёма поставки (kol): 
                <input type="number" name="threshold" value="100" min="0" required>
            </label>
        </p>
        <button type="submit">📊 Выполнить задание 3 (статистика)</button>
    </form>

    <br><br>
    <small>💡 Каждое задание выполняется независимо. Можно запускать сколько угодно раз!</small>
</body>
</html>