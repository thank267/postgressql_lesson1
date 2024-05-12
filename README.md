# Работа с журналами

1) Для установки использовал docker-compose файл, в котором установлены параметры checkpoint_timeout=30s и wal_keep_size=1024:
   [docker-compose файл](/docker_compose_files/postgresql-otus-data_checksums-off-docker-compose.yml)

2) Смотрим до нагрузки Latest checkpoint location и в каком файле находится:
```
select pg_current_wal_lsn();
select pg_walfile_name(pg_current_wal_lsn()); 
 pg_current_wal_lsn 
--------------------
 0/2198660
(1 row)
pg_walfile_name      
--------------------------
 000000010000000000000002
(1 row)

```
3) Даем нагрузку
```
pgbench -c8 -P 6 -T 600

tps = 83.817475 (without initial connection time)
```
3) Смотрим после нагрузки Latest checkpoint location и в каком файле находится:
```
select pg_current_wal_lsn();
select pg_walfile_name(pg_current_wal_lsn());
pg_current_wal_lsn 
--------------------
 0/F654160
(1 row)
pg_walfile_name      
--------------------------
 00000001000000000000000F
(1 row)
```
4) Сгенерировано 16 файлов общим размером 224Mb, размер wal файла 16 384KB:
![wal files](/images/homework6/wal_files.png "wal files")

5) Смотрим статистику контрольных точек:
```
grep -rn '/data/postgres/pg_log/postgresql.log' -e "checkpoint starting: time"

63922:2024-05-12 11:19:47.576 MSK [28] LOG:  checkpoint starting: time
110876:2024-05-12 11:20:17.381 MSK [28] LOG:  checkpoint starting: time
131295:2024-05-12 11:20:47.374 MSK [28] LOG:  checkpoint starting: time
150874:2024-05-12 11:21:17.712 MSK [28] LOG:  checkpoint starting: time
168599:2024-05-12 11:21:47.446 MSK [28] LOG:  checkpoint starting: time
184711:2024-05-12 11:22:17.396 MSK [28] LOG:  checkpoint starting: time
200347:2024-05-12 11:22:47.562 MSK [28] LOG:  checkpoint starting: time
214844:2024-05-12 11:23:17.336 MSK [28] LOG:  checkpoint starting: time
228666:2024-05-12 11:23:47.293 MSK [28] LOG:  checkpoint starting: time
242215:2024-05-12 11:24:17.562 MSK [28] LOG:  checkpoint starting: time
254504:2024-05-12 11:24:47.362 MSK [28] LOG:  checkpoint starting: time
266790:2024-05-12 11:25:17.800 MSK [28] LOG:  checkpoint starting: time
278310:2024-05-12 11:25:47.239 MSK [28] LOG:  checkpoint starting: time
289507:2024-05-12 11:26:17.417 MSK [28] LOG:  checkpoint starting: time
300282:2024-05-12 11:26:47.316 MSK [28] LOG:  checkpoint starting: time
310949:2024-05-12 11:27:17.304 MSK [28] LOG:  checkpoint starting: time
321138:2024-05-12 11:27:47.482 MSK [28] LOG:  checkpoint starting: time
331263:2024-05-12 11:28:17.422 MSK [28] LOG:  checkpoint starting: time
341336:2024-05-12 11:28:47.928 MSK [28] LOG:  checkpoint starting: time
350589:2024-05-12 11:29:17.400 MSK [28] LOG:  checkpoint starting: time
```
В целом все контрольные точки выполнились по расписанию. Мне кажется вполне закономерно, 
т.к. не вылезли за параметр max_wal_size=1Gb размера журнала

6) Даем нагрузку в синхронном режиме:
```
pgbench -P 1 -T 10

pgbench (15.6 (Debian 15.6-1.pgdg120+2))
starting vacuum...end.
progress: 1.0 s, 119.0 tps, lat 6.754 ms stddev 20.867, 0 failed
progress: 2.0 s, 41.0 tps, lat 27.396 ms stddev 64.091, 0 failed
progress: 3.0 s, 49.0 tps, lat 19.954 ms stddev 56.162, 0 failed
progress: 4.0 s, 40.0 tps, lat 22.417 ms stddev 56.360, 0 failed
progress: 5.0 s, 40.0 tps, lat 23.055 ms stddev 58.873, 0 failed
progress: 6.0 s, 50.0 tps, lat 22.773 ms stddev 59.245, 0 failed
progress: 7.0 s, 40.0 tps, lat 26.649 ms stddev 69.073, 0 failed
progress: 8.0 s, 35.0 tps, lat 25.974 ms stddev 71.948, 0 failed
progress: 9.0 s, 30.0 tps, lat 30.283 ms stddev 77.191, 0 failed
progress: 10.0 s, 40.0 tps, lat 26.576 ms stddev 65.627, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 485
number of failed transactions: 0 (0.000%)
latency average = 20.716 ms
latency stddev = 57.769 ms
initial connection time = 70.585 ms
tps = 48.268509 (without initial connection time)
```

Включаем асинхронный режим и даем нагрузку
```
ALTER SYSTEM SET synchronous_commit = off;
SELECT pg_reload_conf();
pgbench -P 1 -T 10

pgbench (15.6 (Debian 15.6-1.pgdg120+2))
starting vacuum...end.
progress: 1.0 s, 119.0 tps, lat 6.452 ms stddev 30.812, 0 failed
progress: 2.0 s, 50.0 tps, lat 22.918 ms stddev 64.389, 0 failed
progress: 3.0 s, 40.0 tps, lat 23.312 ms stddev 64.984, 0 failed
progress: 4.0 s, 40.0 tps, lat 23.920 ms stddev 66.845, 0 failed
progress: 5.0 s, 40.0 tps, lat 23.362 ms stddev 66.203, 0 failed
progress: 6.0 s, 50.0 tps, lat 23.568 ms stddev 66.716, 0 failed
progress: 7.0 s, 45.0 tps, lat 20.628 ms stddev 60.165, 0 failed
progress: 8.0 s, 40.0 tps, lat 22.626 ms stddev 63.747, 0 failed
progress: 9.0 s, 40.0 tps, lat 23.420 ms stddev 66.417, 0 failed
progress: 10.0 s, 50.0 tps, lat 23.469 ms stddev 65.915, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 515
number of failed transactions: 0 (0.000%)
latency average = 19.587 ms
latency stddev = 59.997 ms
initial connection time = 83.163 ms
tps = 51.053162 (without initial connection time)
```

Скорость в асинхронном режиме увеличилась? т.к. не ждем положительного ответа о транзакции

7) Создаем инстанс postgresql с включенной контрольной суммой страниц docker-compose файл:
   [docker-compose файл](/docker_compose_files/postgresql-otus-data_checksums-on-docker-compose.yml)

8) Создаем таблицу, вставляем данные и искажаем их:
```
CREATE TABLE TEST(id integer);
INSERT INTO TEST (id) values (1), (2), (3);
SELECT pg_relation_filepath('TEST');

pg_relation_filepath 
----------------------
 base/5/16386
(1 row)

dd if=/dev/zero of=/data/postgres/base/5/16386 oflag=dsync conv=notrunc bs=1 count=8
```
При селекте получаем ошибку (нарушение контрольной суммы)
```
select * from TEST;
WARNING:  page verification failed, calculated checksum 52381 but expected 23564
ERROR:  invalid page in block 0 of relation base/5/16386
```

Игнорируем ее:
```
SET ignore_checksum_failure = on;
select * from TEST;

WARNING:  page verification failed, calculated checksum 52381 but expected 23564
 id 
----
  1
  2
  3
(3 rows)
```