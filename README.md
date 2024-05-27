# реализовать свой миникластер на 3 ВМ

1) Создаем кластер на 3 ВМ, получаем ip адреса
```
docker network create pgnet
docker run -d --name pgmaster -e POSTGRES_PASSWORD=postgres --network pgnet postgres
docker run -d --name pgslave1 -e POSTGRES_PASSWORD=postgres --network pgnet postgres
docker run -d --name pgslave2 -e POSTGRES_PASSWORD=postgres --network pgnet postgres

docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pgmaster
'172.19.0.2'

docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pgslave1
'172.19.0.3'

docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pgslave2
'172.19.0.4'
```
2) На серверах pgmaster и pgslave1 меняем wal_level:
```
alter system set wal_level = logical;
pg_ctl -D /var/lib/postgresql/data restart
```
3) На серверах pgmaster и pgslave1, pgslave2 создаем таблицы
```
CREATE TABLE test(id int, label text);
CREATE TABLE test2(id int, title text);
```
3) На сервере pgmaster создаем публикацию
```
create publication test_pub for table test;
```
4) на сервере pgslave1 создаем подписку:
```
create subscription test_sub
connection 'host=172.19.0.2 port=5432 user=postgres password=postgres dbname=postgres'
publication test_pub with (copy_data = true);
```
5) Вставляем данные на pgmaster и смотрим на pgslave1
```
pgmaster
INSERT INTO test(label) VALUES ('Раз'), ('Два'), ('Три');

pgslave1
select * from test;
 id | label 
----+-------
    | Раз
    | Два
    | Три
(3 rows)

select * from pg_stat_subscription;

 subid | subname  | pid | leader_pid | relid | received_lsn |      last_msg_send_time       |    last_msg_receipt_time     | latest_end_lsn |        latest_end_time        
-------+----------+-----+------------+-------+--------------+-------------------------------+------------------------------+----------------+-------------------------------
 24583 | test_sub |  33 |            |       | 0/15697E0    | 2024-05-27 18:35:39.705146+00 | 2024-05-27 18:35:39.70525+00 | 0/15697E0      | 2024-05-27 18:35:39.705146+00
(1 row)

```
6) На сервере pgslave1 создаем публикацию
```
create publication test2_pub for table test2;
```
7) на сервере pgmaster создаем подписку:
```
create subscription test2_sub
connection 'host=172.19.0.3 port=5432 user=postgres password=postgres dbname=postgres'
publication test2_pub with (copy_data = true);
```
8) Вставляем данные на pgslave1 и смотрим на pgmaster
```
pgslave1
INSERT INTO test2(title) VALUES ('One'), ('Two'), ('Three');

pgmaster
select * from test2;
 id | title 
----+-------
    | One
    | Two
    | Three
(3 rows)

select * from pg_stat_subscription;
 subid |  subname  | pid | leader_pid | relid | received_lsn |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |        latest_end_time        
-------+-----------+-----+------------+-------+--------------+-------------------------------+-------------------------------+----------------+-------------------------------
 16400 | test2_sub |  89 |            |       | 0/1567468    | 2024-05-27 18:24:43.329068+00 | 2024-05-27 18:24:43.329309+00 | 0/1567468      | 2024-05-27 18:24:43.329068+00
(1 row)
```
9) Делаем подписки на pgslave2 и проверяем данные
```
create subscription test_sub
connection 'host=172.19.0.2 port=5432 user=postgres password=postgres dbname=postgres'
publication test_pub with (copy_data = true, slot_name = test_read);
NOTICE:  created replication slot "test_read" on publisher
CREATE SUBSCRIPTION

create subscription test2_sub
connection 'host=172.19.0.3 port=5432 user=postgres password=postgres dbname=postgres'
publication test2_pub with (copy_data = true, slot_name = test2_read);
NOTICE:  created replication slot "test2_read" on publisher
CREATE SUBSCRIPTION

select * from test;
 id | label 
----+-------
    | Раз
    | Два
    | Три
(3 rows)

select * from test2;
 id | title 
----+-------
    | One
    | Two
    | Three
(3 rows)

select * from pg_stat_subscription;
 subid |  subname  | pid | leader_pid | relid | received_lsn |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |        latest_end_time        
-------+-----------+-----+------------+-------+--------------+-------------------------------+-------------------------------+----------------+-------------------------------
 24587 | test_sub  |  46 |            |       | 0/15697E0    | 2024-05-27 18:34:09.594029+00 | 2024-05-27 18:34:09.594154+00 | 0/15697E0      | 2024-05-27 18:34:09.594029+00
 24588 | test2_sub |  50 |            |       | 0/15675C0    | 2024-05-27 18:34:10.787819+00 | 2024-05-27 18:34:10.787911+00 | 0/15675C0      | 2024-05-27 18:34:10.787819+00
(2 rows)
```

