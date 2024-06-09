# Работа с индексами

Устанавливаем дистрибутив Postgresql 15.7 c с помощью [docker-compose файл](/docker_compose_files/postgresql-15-otus-docker-compose.yml)
Загружаем DVD Rental database
```
pg_restore -U postgres -d postgres /tmp/dvdrental/dvdrental.tar

```
1) Создать индекс к какой-либо из таблиц вашей БД
```
CREATE INDEX IF NOT EXISTS idx_actor_first_name
    ON public.actor USING btree
    (first_name COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

создали индекс для таблицы actor для поля first_name
```
2) Прислать текстом результат команды explain, в которой используется данный индекс
```
т.к. таблица небольшая - принудительно отключим seq scan
set enable_seqscan = off;

explain select * from actor
where first_name = 'Bob';
                                    QUERY PLAN                                     
-----------------------------------------------------------------------------------
 Index Scan using idx_actor_first_name on actor  (cost=0.14..8.16 rows=1 width=25)
   Index Cond: ((first_name)::text = 'Bob'::text)
(2 rows)
```

3) Реализовать индекс для полнотекстового поиска
```
поиграемся с таблицей film. Она содержит полнотектоый индекс gist film_fulltext_idx и поле fulltext типа tsvector.
Удалим их
DROP INDEX film_fulltext_idx;
ALTER TABLE film DROP COLUMN fulltext;

создадим новую колонку с векторами для полнотекстового поиска
ALTER TABLE film ADD COLUMN fulltext TSVECTOR GENERATED ALWAYS
AS (to_tsvector('english', description)) STORED;

создаем индекс для полнотестового поиска
CREATE INDEX idx_film_fulltext ON film USING gin
(fulltext);

тестируем
EXPLAIN SELECT title, description FROM film WHERE fulltext @@
to_tsquery('english', 'drama');
                                    QUERY PLAN                                   
--------------------------------------------------------------------------------
 Bitmap Heap Scan on film  (cost=8.04..23.40 rows=5 width=109)
   Recheck Cond: (fulltext @@ '''drama'''::tsquery)
   ->  Bitmap Index Scan on idx_film_fulltext  (cost=0.00..8.04 rows=5 width=0)
         Index Cond: (fulltext @@ '''drama'''::tsquery)
(4 rows)
```

4) Реализовать индекс на часть таблицы или индекс на поле с функцией
```
CREATE INDEX IF NOT EXISTS idx_city_city
ON public.city (city)
WHERE left(city, 1) = 'A'

тестируем
set enable_seqscan = off;
explain select * from city
where left(city,1) ='A';
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Index Scan using idx_city_city on city  (cost=0.14..8.19 rows=3 width=23)
(1 row)
```

5) Создать индекс на несколько полей
```
CREATE INDEX ON address(address, address2);

тестируем
set enable_seqscan = off;
explain select * from address
where address is null or address2 is null
                                            QUERY PLAN                                            
--------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on address  (cost=33.08..40.64 rows=4 width=61)
   Recheck Cond: ((address IS NULL) OR (address2 IS NULL))
   ->  BitmapOr  (cost=33.08..33.08 rows=4 width=0)
         ->  Bitmap Index Scan on address_address_address2_idx  (cost=0.00..4.28 rows=1 width=0)
               Index Cond: (address IS NULL)
         ->  Bitmap Index Scan on address_address_address2_idx  (cost=0.00..28.80 rows=4 width=0)
               Index Cond: (address2 IS NULL)
(7 rows)
```

6) Не совсем понял что надо сделать
7) В целом не сложно. Часто включался seq scan, и планировщик не переключал на требуемый индекс, приходилось контролировать значение enable_seqscan