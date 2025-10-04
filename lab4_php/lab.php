    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Лабораторная работа по PHP</title>
    </head>
    <body>
        <h2>Введите данные для выполнения заданий</h2>
        <form method="post" action="process.php">
            <p>
                <label>Имя нового поставщика: 
                    <input type="text" name="sname" required>
                </label>
            </p>
            <p>
                <label>Город изделия (для удаления детали): 
                    <input type="text" name="jtown" required>
                </label>
            </p>
            <p>
                <label>Порог объёма поставки (kol): 
                    <input type="number" name="threshold" value="100" min="0" required>
                </label>
            </p>
            <button type="submit">Выполнить задания</button>
        </form>
    </body>
    </html>