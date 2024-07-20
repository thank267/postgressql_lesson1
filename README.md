# Триггеры, поддержка заполнения витрин

Устанавливаем дистрибутив Postgresql 15.7 c с помощью [docker-compose файл](./docker_compose_files/postgresql-15-otus-docker-compose.yml)
Также в docker-compose файл подключены инициализационный скрипт с начальными данными [hw_triggers.sql](./script/hw_triggers.sql) и
мнициализационный скрипт с триггерами из домашнего задания [my_trigger.sql](./script/my_trigger.sql)

1) Проверяем INSERT
```
SET search_path = pract_functions, publ;
INSERT INTO sales (good_id, sales_qty) values (1, 10), (1, 10);

SELECT * from good_sum_mart;
      good_name       | sum_sale 
----------------------+----------
 Спички хозайственные |    75.50
(1 row)
```

2) Проверяем UPDATE
```
SET search_path = pract_functions, publ;
UPDATE sales
SET good_id = 1, sales_qty = 10
WHERE sales_id=4; 

        good_name         | sum_sale 
--------------------------+----------
 Автомобиль Ferrari FXX K |     0.00
 Спички хозайственные     |    80.50
(2 rows)
```

3Проверяем DELETE
```
SET search_path = pract_functions, publ;
DELETE FROM sales;

        good_name         | sum_sale 
--------------------------+----------
 Автомобиль Ferrari FXX K |     0.00
 Спички хозайственные     |     0.00
(2 rows)
```