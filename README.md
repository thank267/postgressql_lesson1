# Настройка autovacuum с учетом особеностей производительности

1) Для установки использовал docker-compose файл:
   [docker-compose файл](/docker_compose_files/postgresql-otus-docker-compose.yml)

2) Число процессоров изменить нельзя. Установил резервы по памяти 4Gb, диск внешний, поэтому лимитировал размером свободного диска на ноутбуке
3) Создаю тестовую бд
```
pgbench -i postgres -U postgres
```
3) Запускаю тест
```
pgbench -c8 -P 6 -T 60 -U postgres postgres;
```
4) Получаю результат
```
pgbench (15.6 (Debian 15.6-1.pgdg120+2))
starting vacuum...end.
progress: 6.0 s, 548.0 tps, lat 14.485 ms stddev 12.029, 0 failed
progress: 12.0 s, 539.7 tps, lat 14.811 ms stddev 11.589, 0 failed
progress: 18.0 s, 542.3 tps, lat 14.748 ms stddev 11.978, 0 failed
progress: 24.0 s, 609.3 tps, lat 13.123 ms stddev 10.699, 0 failed
progress: 30.0 s, 590.2 tps, lat 13.542 ms stddev 11.419, 0 failed
progress: 36.0 s, 591.3 tps, lat 13.515 ms stddev 11.603, 0 failed
progress: 42.0 s, 612.7 tps, lat 13.036 ms stddev 10.623, 0 failed
progress: 48.0 s, 621.8 tps, lat 12.854 ms stddev 10.211, 0 failed
progress: 54.0 s, 624.8 tps, lat 12.792 ms stddev 10.825, 0 failed
progress: 60.0 s, 608.8 tps, lat 13.108 ms stddev 10.565, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 35342
number of failed transactions: 0 (0.000%)
latency average = 13.563 ms
latency stddev = 11.168 ms
initial connection time = 23.770 ms
tps = 589.130461 (without initial connection time)
```
5) Меняю настройки бд в файле postgresql.conf. По-моему, они не относятся к вакууму/автовакууму:)
```
max_connections = 40
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 500
random_page_cost = 4
effective_io_concurrency = 2
work_mem = 6553kB
min_wal_size = 4GB
max_wal_size = 16GB
```
6) Запускаю тест
```
pgbench -c8 -P 6 -T 60 -U postgres postgres;
```
7) И не понимаю закономерности
```
pgbench (15.6 (Debian 15.6-1.pgdg120+2))
starting vacuum...end.
progress: 6.0 s, 540.3 tps, lat 14.711 ms stddev 11.939, 0 failed
progress: 12.0 s, 610.7 tps, lat 13.091 ms stddev 10.471, 0 failed
progress: 18.0 s, 611.7 tps, lat 13.062 ms stddev 10.498, 0 failed
progress: 24.0 s, 607.2 tps, lat 13.129 ms stddev 10.541, 0 failed
progress: 30.0 s, 609.8 tps, lat 13.127 ms stddev 10.560, 0 failed
progress: 36.0 s, 611.3 tps, lat 13.065 ms stddev 9.749, 0 failed
progress: 42.0 s, 603.3 tps, lat 13.245 ms stddev 10.487, 0 failed
progress: 48.0 s, 571.7 tps, lat 13.990 ms stddev 11.182, 0 failed
progress: 54.0 s, 537.3 tps, lat 14.882 ms stddev 11.516, 0 failed
progress: 60.0 s, 525.7 tps, lat 15.179 ms stddev 11.733, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 34982
number of failed transactions: 0 (0.000%)
latency average = 13.704 ms
latency stddev = 10.885 ms
initial connection time = 23.265 ms
tps = 583.021245 (without initial connection time)
```
8) Создаю таблицу с текстовым полем
```
CREATE TABLE student(fio char(100));
```
9) Заполняю таблицу
```
INSERT INTO student(fio) SELECT 'noname' FROM generate_series(1,1000000);
```
10) Проверяем размер
```
SELECT pg_size_pretty(pg_total_relation_size('student'));
pg_size_pretty 
----------------
 128 MB
(1 row)
```
11) Обновляю 5 раз строчки таблицы
```
DO
$$
declare
i int;
repeat_times int;
begin
select 5 INTO repeat_times;
for i in select generate_series(1,repeat_times)
loop
        update student set fio = fio||i;
end loop;
end;
$$;
```
12) Смотрим количество мертвых строчек в таблице и когда последний раз происходил автовакуум
```
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables WHERE relname = 'student'; 
 
 relname | n_live_tup | n_dead_tup |        last_autovacuum        
---------+------------+------------+-------------------------------
 student |    1000000 |    5000000 | 2024-05-04 23:13:18.443439+03
(1 row)
```
13) Видим что 5 000 000 (5 x 1 000 000). Ждем и повторяем. Видим что автовакуум отработал
```
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables WHERE relname = 'student'; 
 relname | n_live_tup | n_dead_tup |        last_autovacuum        
---------+------------+------------+-------------------------------
 student |    1003561 |          0 | 2024-05-04 23:18:30.779704+03
(1 row)
```
14) Снова обновляю 5 раз строчки таблицы
```
DO
$$
declare
i int;
repeat_times int;
begin
select 5 INTO repeat_times;
for i in select generate_series(1,repeat_times)
loop
        update student set fio = fio||i;
end loop;
end;
$$;
```
15) Смотрю ее физический размер. Размер вырос из-за мертвых кортежей и общего роста размера поля fio
```
SELECT pg_size_pretty(pg_total_relation_size('student'));
 pg_size_pretty 
----------------
 769 MB
(1 row)
```
22) Отключаю автовакуум на таблице student
```
ALTER TABLE student SET (autovacuum_enabled = off);
```
23) Обновляю ее 10 раз
```
DO
$$
declare
i int;
repeat_times int;
begin
select 10 INTO repeat_times;
for i in select generate_series(1,repeat_times)
loop
        update student set fio = fio||i;
end loop;
end;
$$;
```
24) Смотрю ее физический размер. Размер вырос из-за мертвых кортежей и общего роста размера поля fio
```
SELECT pg_size_pretty(pg_total_relation_size('student'));
 pg_size_pretty 
----------------
 1409 MB
(1 row)

SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables WHERE relname = 'student';
 relname | n_live_tup | n_dead_tup |        last_autovacuum        
---------+------------+------------+-------------------------------
 student |    1010462 |   10000000 | 2024-05-04 23:26:34.875695+03
(1 row)
```
25) Восстанавливаем автовакуум
```
ALTER TABLE student SET (autovacuum_enabled = on);
```