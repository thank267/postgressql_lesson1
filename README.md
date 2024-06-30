# Работа с индексами

Устанавливаем дистрибутив Postgresql 15.7 c с помощью [docker-compose файл](/docker_compose_files/postgresql-15-otus-docker-compose.yml)
Загружаем DVD Rental database
```
pg_restore -U postgres -d postgres /tmp/dvdrental/dvdrental.tar

```

1) Реализовать прямое соединение двух или более таблиц
```
select city, country from city 
inner join country using (country_id) 

Successfully run. Total query runtime: 82 msec.
600 rows affected.

Выводятся городв и страны в которых они находятся. связка по ключу country_id
```

2) Реализовать левостороннее (или правостороннее)
   соединение двух или более таблиц
```
select city, country from city 
left outer join country using (country_id) 

Successfully run. Total query runtime: 84 msec.
600 rows affected.

Выводятся городв и страны в которых они находятся, также города в которых страна не указана.
связка по ключу country_id. Одинаковое число строк в результатах запроса с 1, говорит о том, что все города приявязаны к конкретной стране.
```

3) Реализовать кросс соединение двух или более таблиц
```
select city, country from city, country

Successfully run. Total query runtime: 110 msec.
65400 rows affected.

декартово произведенее 600 x 109 = 65400. Без комментариев
```

4) Реализовать полное соединение двух или более таблиц
```
select city, country from city 
full outer join country using (country_id) 

Successfully run. Total query runtime: 232 msec.
600 rows affected.

Одинаковое число срок с 1-м и 2-м запросом. Нет городов без стран. Нет стран без городов
```

5) Реализовать запрос, в котором будут использованы
   разные типы соединений
```
select count(*) from actor
right join (select last_name from customer 
inner join staff using (last_name)) as ln using (last_name)
WHERE ln.last_name IS NOT NULL


Successfully run. Total query runtime: 78 msec.
1 rows affected.

count 
-------
     0
(1 row)

Ищем актеров, которые не однофамильцы одновременно клиентов и сотрудников. Таких нет в дефолтных данных. 
```