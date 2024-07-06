# Работа с индексами

Устанавливаем дистрибутив Postgresql 15.7 c с помощью [docker-compose файл](/docker_compose_files/postgresql-15-otus-docker-compose.yml)
Загружаем demo database flights
```
psql -f /tmp/demo-big-en-20170815.sql -U postgres

```
1) Самая большая таблица tickets, будем партиционировать ее по hash по полю book_ref. Подготовим таблицу
```
begin;

create table tickets_temp (like tickets including all);

alter table tickets_temp
    drop constraint tickets_temp_pkey,
    add primary key (ticket_no, book_ref);

create table tickets_partitions (like tickets_temp including all)
    PARTITION BY HASH (book_ref);

drop table tickets_temp;

commit;
```

2) Создадим секции с модулем 10
```
do $$
begin
for i in 0 .. 9
	loop
		execute format('create table tickets_partitions_%s partition of tickets_partitions for values with (modulus 10, remainder %s);', i, i);
	end loop;
end;
$$ language plpgsql;
```

3) Копируем данные из tickets в tickets_partitions
```
INSERT INTO tickets_partitions
SELECT * FROM tickets;
```

4) Проверяем, что чтение прошло из нужной партиции
```
explain analyze select * from tickets_partitions where book_ref='CB1DF3';
                                                                      QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..7468.22 rows=2 width=104) (actual time=0.331..24.444 rows=1 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on tickets_partitions_0 tickets_partitions  (cost=0.00..6468.02 rows=1 width=104) (actual time=10.723..1
7.511 rows=0 loops=3)
         Filter: (book_ref = 'CB1DF3'::bpchar)
         Rows Removed by Filter: 98177
 Planning Time: 0.146 ms
 Execution Time: 24.463 ms
``