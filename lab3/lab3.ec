#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ecpglib.h>
#include <ecpgerrno.h>
#include <sqlca.h>

/* Прототипы функций */
void query1();
void query2();
void query3();
void query4();
void query5();

int main() {
    /* Подключение к базе данных */
    printf("Подключение к базе данных...\n");
    EXEC SQL CONNECT TO students@fpm2.ami.nstu.ru:5432 USER "YOUR_USER" USING "YOUR_PASSWORD";
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка подключения к базе данных: %s\n", sqlca.sqlerrm.sqlerrmc);
        exit(EXIT_FAILURE);
    }
    printf("Подключение к базе данных прошло успешно.\n");

    int choice;
    char ch;
    do {
        /* Меню */

        printf("\nВыберите запрос для выполнения:\n");
        printf("1. Подсчитать количество деталей по критериям.\n");
        printf("2. Обменять вес деталей из Рима и Парижа.\n");
        printf("3. Вывести детали с объемом поставки <= половине максимального из Парижа.\n");
        printf("4. Вывести поставщиков, не поставлявших детали для изделий из Парижа.\n");
        printf("5. Вывести поставщиков, поставлявших что-то, но НЕ для изделий с >3 деталями.\n");
        printf("0. Выход.\n");
        printf("Введите ваш выбор: ");

        if (scanf("%d", &choice) != 1) {
            while ((ch = getchar()) != '\n' && ch != EOF);
            choice = -1;
        }

        switch (choice) {
            case 1:
                query1();
                break;
            case 2:
                query2();
                break;
            case 3:
                query3();
                break;
            case 4:
                query4();
                break;
            case 5:
                query5();
                break;
            case 0:
                printf("Завершение программы...\n");
                break;
            default:
                printf("Неверный выбор. Пожалуйста, попробуйте снова.\n");
        }
    } while (choice != 0);

    /* Отключение от базы данных */
    printf("Отключение от базы данных...\n");
    EXEC SQL DISCONNECT;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка отключения от базы данных: %s\n", sqlca.sqlerrm.sqlerrmc);
        exit(EXIT_FAILURE);
    }
    printf("Отключение от базы данных прошло успешно.\n");

    return EXIT_SUCCESS;
}

/* Функция для запроса 1 */
void query1() {
    EXEC SQL BEGIN DECLARE SECTION;
    int detail_count = 0;
    EXEC SQL END DECLARE SECTION;

    printf("Начало транзакции...\n");
    EXEC SQL BEGIN WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка начала транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("Выполнение запроса...\n");
    EXEC SQL
        SELECT COUNT(DISTINCT spj.n_det)
        INTO :detail_count
        FROM pmib2309.spj AS spj
        WHERE spj.n_izd IN (
            SELECT DISTINCT spj_inner.n_izd
            FROM pmib2309.spj AS spj_inner
            JOIN pmib2309.p AS p_inner ON spj_inner.n_det = p_inner.n_det
            WHERE (p_inner.ves * spj_inner.kol) BETWEEN 5000 AND 6000
        );
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка выполнения запроса: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }
    printf("Количество деталей: %d\n", detail_count);

    EXEC SQL COMMIT WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка завершения транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }
    printf("Транзакция завершена успешно.\n");
}

/* Функция для запроса 2 */
void query2() {
    printf("Начало транзакции...\n");
    EXEC SQL BEGIN WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка начала транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("Обмен весов деталей из Рима и Парижа...\n");
    EXEC SQL
        UPDATE pmib2309.p
        SET ves = CASE
            WHEN town = 'Рим' THEN (SELECT MIN(ves) FROM pmib2309.p WHERE town = 'Париж')
            WHEN town = 'Париж' THEN (SELECT MIN(ves) FROM pmib2309.p WHERE town = 'Рим')
            ELSE ves
        END
        WHERE town = 'Рим' OR town = 'Париж';
    if (sqlca.sqlcode == 0) {
        printf("Вес деталей успешно обновлён.\n");
        printf("Количество обновлённых строк: %ld\n", sqlca.sqlerrd[2]);
    } else {
        fprintf(stderr, "Ошибка при обновлении весов: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    EXEC SQL COMMIT WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка завершения транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }
    printf("Транзакция завершена успешно.\n");
}

/* Функция для запроса 3 */
void query3() {
    EXEC SQL BEGIN DECLARE SECTION;
    char n_det[7];
    char name[21];
    char cvet[21];
    int ves;
    char town[21];
    EXEC SQL END DECLARE SECTION;

    printf("Начало транзакции...\n");
    EXEC SQL BEGIN WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка начала транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("Открытие курсора...\n");
    EXEC SQL DECLARE parts_cursor_q3 CURSOR FOR
        SELECT DISTINCT p.n_det, p.name, p.cvet, p.ves, p.town
        FROM pmib2309.spj AS spj
        JOIN pmib2309.p AS p ON spj.n_det = p.n_det
        JOIN (
            SELECT spj_sub.n_det, MAX(p_sub.ves * spj_sub.kol) AS max_volume
            FROM pmib2309.spj AS spj_sub
            JOIN pmib2309.s AS s_sub ON spj_sub.n_post = s_sub.n_post
            JOIN pmib2309.p AS p_sub ON spj_sub.n_det = p_sub.n_det
            WHERE s_sub.town = 'Париж'
            GROUP BY spj_sub.n_det
        ) AS max_volume_paris ON spj.n_det = max_volume_paris.n_det
        WHERE (p.ves * spj.kol) <= (max_volume_paris.max_volume / 2);
    EXEC SQL OPEN parts_cursor_q3;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка открытия курсора: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("\nДетали с объемом поставки <= половине максимального из Парижа:\n");
    EXEC SQL FETCH parts_cursor_q3 INTO :n_det, :name, :cvet, :ves, :town;
    if (sqlca.sqlcode == 100) {
        printf("Данных не найдено.\n");
    } else if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка при получении данных: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL CLOSE parts_cursor_q3;
        EXEC SQL ROLLBACK WORK;
        return;
    } else {
        printf("---------------------------------------------------------------------------------------------\n");
        printf("%-7s | %-25s | %-18s | %-11s | %-20s\n", "n_det", "Название", "Цвет", "Вес", "Город");
        printf("---------------------------------------------------------------------------------------------\n");
        printf("%-7s | %-20s | %-18s | %-8d | %-20s\n", n_det, name, cvet, ves, town);
    }
    while (1) {
        EXEC SQL FETCH parts_cursor_q3 INTO :n_det, :name, :cvet, :ves, :town;
        if (sqlca.sqlcode == 100) {
            break;
        } else if (sqlca.sqlcode < 0) {
            fprintf(stderr, "Ошибка при получении данных: %s\n", sqlca.sqlerrm.sqlerrmc);
            EXEC SQL CLOSE parts_cursor_q3;
            EXEC SQL ROLLBACK WORK;
            return;
        }
        printf("%-7s | %-20s | %-18s | %-8d | %-20s\n", n_det, name, cvet, ves, town);
    }

    EXEC SQL CLOSE parts_cursor_q3;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка закрытия курсора: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    EXEC SQL COMMIT WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка завершения транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }
    printf("Транзакция завершена успешно.\n");
}

/* Функция для запроса 4 */
void query4() {
    EXEC SQL BEGIN DECLARE SECTION;
    char s_n_post[7];
    char s_name[21];
    int s_reiting;
    char s_town[21];
    EXEC SQL END DECLARE SECTION;

    printf("Начало транзакции...\n");
    EXEC SQL BEGIN WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка начала транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("Открытие курсора...\n");
    EXEC SQL DECLARE supplier_cursor_q4 CURSOR FOR
        SELECT s.n_post, s.name, s.reiting, s.town
        FROM pmib2309.s AS s
        WHERE s.n_post IN (
            SELECT DISTINCT spj_outer.n_post
            FROM pmib2309.spj AS spj_outer
            WHERE spj_outer.n_det IN (
                SELECT DISTINCT spj_inner.n_det
                FROM pmib2309.spj AS spj_inner
                WHERE spj_inner.n_izd IN (
                    SELECT j.n_izd
                    FROM pmib2309.j AS j
                    WHERE TRIM(LOWER(j.town)) = 'париж'
                )
            )
        );
    EXEC SQL OPEN supplier_cursor_q4;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка открытия курсора: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("\nПоставщики, поставлявшие детали, используемые в изделиях из Парижа:\n");
    int found = 0;
    while (1) {
        EXEC SQL FETCH supplier_cursor_q4 INTO :s_n_post, :s_name, :s_reiting, :s_town;
        if (sqlca.sqlcode == 100) break;
        if (sqlca.sqlcode < 0) {
            fprintf(stderr, "Ошибка при получении данных: %s\n", sqlca.sqlerrm.sqlerrmc);
            EXEC SQL CLOSE supplier_cursor_q4;
            EXEC SQL ROLLBACK WORK;
            return;
        }
        if (!found) {
            printf("--------------------------------------------------------------------------\n");
            printf("%-10s | %-24s | %-7s | %-20s\n", "n_post", "Название", "Рейтинг", "Город");
            printf("--------------------------------------------------------------------------\n");
            found = 1;
        }
        printf("%-10s | %-20s | %-7d | %-20s\n", s_n_post, s_name, s_reiting, s_town);
    }

    if (!found) {
        printf("Данных не найдено.\n");
    }

    EXEC SQL CLOSE supplier_cursor_q4;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка закрытия курсора: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    EXEC SQL COMMIT WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка завершения транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }
    printf("Транзакция завершена успешно.\n");
}


/* Функция для запроса 5 — обновлённая версия */
void query5() {
    EXEC SQL BEGIN DECLARE SECTION;
    char s_n_post[7];
    char s_name[21];
    int s_reiting;
    char s_town[21];
    EXEC SQL END DECLARE SECTION;

    printf("Начало транзакции...\n");
    EXEC SQL BEGIN WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка начала транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("Открытие курсора...\n");
    EXEC SQL DECLARE supplier_cursor_q5 CURSOR FOR
        SELECT s.n_post, s.name, s.reiting, s.town
        FROM pmib2309.s AS s
        WHERE EXISTS (
            SELECT 1 FROM pmib2309.spj AS spj WHERE spj.n_post = s.n_post
        )
        AND NOT EXISTS (
            SELECT 1
            FROM pmib2309.spj AS spj
            WHERE spj.n_post = s.n_post
              AND spj.n_izd IN (
                  SELECT n_izd
                  FROM pmib2309.spj
                  GROUP BY n_izd
                  HAVING COUNT(DISTINCT n_det) > 3
              )
        );
    EXEC SQL OPEN supplier_cursor_q5;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка открытия курсора: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    printf("\nПоставщики, поставлявшие что-то, но НЕ для изделий с >3 деталями:\n");
    EXEC SQL FETCH supplier_cursor_q5 INTO :s_n_post, :s_name, :s_reiting, :s_town;
    if (sqlca.sqlcode == 100) {
        printf("Данных не найдено.\n");
    } else if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка при получении данных: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL CLOSE supplier_cursor_q5;
        EXEC SQL ROLLBACK WORK;
        return;
    } else {
        printf("--------------------------------------------------------------------------\n");
        printf("%-10s | %-24s | %-7s | %-20s\n", "n_post", "Название", "Рейтинг", "Город");
        printf("--------------------------------------------------------------------------\n");
        printf("%-10s | %-20s | %-7d | %-20s\n", s_n_post, s_name, s_reiting, s_town);
    }

    while (1) {
        EXEC SQL FETCH supplier_cursor_q5 INTO :s_n_post, :s_name, :s_reiting, :s_town;
        if (sqlca.sqlcode == 100) {
            break;
        } else if (sqlca.sqlcode < 0) {
            fprintf(stderr, "Ошибка при получении данных: %s\n", sqlca.sqlerrm.sqlerrmc);
            EXEC SQL CLOSE supplier_cursor_q5;
            EXEC SQL ROLLBACK WORK;
            return;
        }
        printf("%-10s | %-20s | %-7d | %-20s\n", s_n_post, s_name, s_reiting, s_town);
    }

    EXEC SQL CLOSE supplier_cursor_q5;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка закрытия курсора: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }

    EXEC SQL COMMIT WORK;
    if (sqlca.sqlcode < 0) {
        fprintf(stderr, "Ошибка завершения транзакции: %s\n", sqlca.sqlerrm.sqlerrmc);
        EXEC SQL ROLLBACK WORK;
        return;
    }
    printf("Транзакция завершена успешно.\n");
}
