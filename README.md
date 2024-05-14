# Механизм блокировок

1) Для установки использовал docker-compose файл, в котором установлены параметры log_lock_waits=on и deadlock_timeout=200ms:
   [docker-compose файл](/docker_compose_files/postgresql-otus-data_checksums-off-docker-compose.yml)

2) Для моделирования будем использовать таблицу category из DVD Rental database:
```
сессия 1
BEGIN;
UPDATE category SET name = 'Action 1' WHERE category_id = 1;

сессия 2 
BEGIN;
UPDATE category SET name = 'Action 1' WHERE category_id = 1;
```
Во второй сессии GUI подвесилось
   ![Блокировка](/images/homework7/case_1.png "Блокировка")

Коммитим обе сессии и смотрим логи:
```
tail -n 12 /data/postgres/pg_log/postgresql.log

2024-05-12 21:08:16.060 MSK [148] LOG:  statement: BEGIN;
	UPDATE category SET name = 'Action 2' WHERE category_id = 1;
2024-05-12 21:08:16.262 MSK [148] LOG:  process 148 still waiting for ShareLock on transaction 918 after 200.163 ms
2024-05-12 21:08:16.262 MSK [148] DETAIL:  Process holding the lock: 145. Wait queue: 148.
2024-05-12 21:08:16.262 MSK [148] CONTEXT:  while locking tuple (0,1) in relation "category"
2024-05-12 21:08:16.262 MSK [148] STATEMENT:  BEGIN;
	UPDATE category SET name = 'Action 2' WHERE category_id = 1;
2024-05-12 21:09:29.118 MSK [145] LOG:  statement: COMMIT;
2024-05-12 21:09:29.127 MSK [148] LOG:  process 148 acquired ShareLock on transaction 918 after 73065.023 ms
2024-05-12 21:09:29.127 MSK [148] CONTEXT:  while locking tuple (0,1) in relation "category"
2024-05-12 21:09:29.127 MSK [148] STATEMENT:  BEGIN;
	UPDATE category SET name = 'Action 2' WHERE category_id = 1;
2024-05-12 21:13:55.723 MSK [148] LOG:  statement: BEGIN;
	UPDATE category SET name = 'Action 2' WHERE category_id = 1;
	commit;
2024-05-12 21:13:55.723 MSK [148] WARNING:  there is already a transaction in progress

```
2) Также будем использовать для моделирования трех update таблицу category из DVD Rental database (case 2)
```
сессия 1
BEGIN;
SELECT txid_current(), pg_backend_pid();
 txid_current | pg_backend_pid 
--------------+----------------
          940 |             94
(1 row)
UPDATE category SET name = name||1 WHERE category_id = 1;

SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks WHERE pid = 94;

   locktype    |   relation    | virtxid | xid |       mode       | granted
---------------+---------------+---------+-----+------------------+---------
 relation      | category_pkey |         |     | RowExclusiveLock | t
 relation      | category      |         |     | RowExclusiveLock | t
 virtualxid    |               | 12/7    |     | ExclusiveLock    | t
 transactionid |               |         | 940 | ExclusiveLock    | t
(4 rows)

ExclusiveLock - необходимор для самой транзакции (типы virtualxid и transactionid)
RowExclusiveLock - на то что изменяем и на pkey

сессия 2 
BEGIN;
SELECT txid_current(), pg_backend_pid();
 txid_current | pg_backend_pid 
--------------+----------------
          941 |             95
(1 row)
UPDATE category SET name = name||2 WHERE category_id = 1;

SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks WHERE pid = 95;

   locktype    |   relation    | virtxid | xid |       mode       | granted
---------------+---------------+---------+-----+------------------+---------
 relation      | category_pkey |         |     | RowExclusiveLock | t
 relation      | category      |         |     | RowExclusiveLock | t
 virtualxid    |               | 13/2    |     | ExclusiveLock    | t
 tuple         | category      |         |     | ExclusiveLock    | t
 transactionid |               |         | 940 | ShareLock        | f
 transactionid |               |         | 941 | ExclusiveLock    | t
(6 rows)

ExclusiveLock - необходимор для самой транзакции (типы virtualxid и transactionid)
ExclusiveLock - блокировка на обновляемую строку
ShareLock - ожидает блокировки от транзакции 940 (первой)
RowExclusiveLock - на то что изменяем и на pkey

сессия 3 
BEGIN;
SELECT txid_current(), pg_backend_pid();
 txid_current | pg_backend_pid 
--------------+----------------
          942|             96
(1 row)
UPDATE category SET name = name||3 WHERE category_id = 1;

SELECT locktype, relation::REGCLASS, virtualxid AS virtxid, transactionid AS xid, mode, granted FROM pg_locks WHERE pid = 96;

   locktype    |   relation    | virtxid | xid |       mode       | granted
---------------+---------------+---------+-----+------------------+---------
 relation      | category_pkey |         |     | RowExclusiveLock | t
 relation      | category      |         |     | RowExclusiveLock | t
 virtualxid    |               | 14/2    |     | ExclusiveLock    | t
 tuple         | category      |         |     | ExclusiveLock    | f
 transactionid |               |         | 942 | ExclusiveLock    | t
(5 rows)

ExclusiveLock - необходимор для самой транзакции (типы virtualxid и transactionid)
ExclusiveLock - ожидание блокировки на обновляемую строку (false)
RowExclusiveLock - на то что изменяем и на pkey
```


4) Воспроизведите взаимоблокировку трех транзакций (case 3)
```
сессия 1
BEGIN;
UPDATE category SET name = name||1 WHERE category_id = 1;
UPDATE category SET name = name||2 WHERE category_id = 2;

сессия 2
BEGIN;
UPDATE category SET name = name||2 WHERE category_id = 2;
UPDATE category SET name = name||3 WHERE category_id = 3;

сессия 3
BEGIN;
UPDATE category SET name = name||3 WHERE category_id = 3;
UPDATE category SET name = name||1 WHERE category_id = 1;

Смотрим логи tail -n 10 /data/postgres/pg_log/postgresql.log

2024-05-14 20:17:01.449 MSK [51] ERROR:  deadlock detected
2024-05-14 20:17:01.449 MSK [51] DETAIL:  Process 51 waits for ShareLock on transaction 951; blocked by process 47.
	Process 47 waits for ShareLock on transaction 952; blocked by process 46.
	Process 46 waits for ShareLock on transaction 953; blocked by process 51.
	Process 51: UPDATE category SET name = name||1 WHERE category_id = 1
	Process 47: UPDATE category SET name = name||2 WHERE category_id = 2
	Process 46: UPDATE category SET name = name||3 WHERE category_id = 3
2024-05-14 20:17:01.449 MSK [51] HINT:  See server log for query details.
2024-05-14 20:17:01.449 MSK [51] CONTEXT:  while locking tuple (0,48) in relation "category"
2024-05-14 20:17:01.449 MSK [51] STATEMENT:  UPDATE category SET name = name||1 WHERE category_id = 1
```

5) Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?
```
Да, когда идет update таблицы в разные стороны. Например 

сесиия 1
begin;
declare a CURSOR FOR SELECT * FROM category ORDER BY category_id ASC
FOR UPDATE;  
fetch 9 from a;

сесиия 2
begin;
declare d CURSOR FOR SELECT * FROM category ORDER BY category_id DESC 
FOR UPDATE;  
fetch 9 from d;

"Столнули" транзакции, далее
fetch 1 from d;
И получаем:

ERROR:  Process 117 waits for ShareLock on transaction 962; blocked by process 102.
Process 102 waits for ShareLock on transaction 961; blocked by process 117.deadlock detected 

ERROR:  deadlock detected
SQL state: 40P01
Detail: Process 117 waits for ShareLock on transaction 962; blocked by process 102.
Process 102 waits for ShareLock on transaction 961; blocked by process 117.
Hint: See server log for query details.
Context: while locking tuple (0,7) in relation "category"

```

