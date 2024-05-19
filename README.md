# применить логический бэкап. Восстановиться из бэкапа

1) Устанавливаем дистрибутив Postgresql 15.7 c с помощью [docker-compose файл](/docker_compose_files/postgresql-15-otus-docker-compose.yml)
2) Загружаем DVD Rental database
```
pg_restore -U postgres -d postgres /tmp/dvdrental/dvdrental.tar
```
3) Копируем таблицу actor:
```
\copy actor to '/tmp/actor.sql';
COPY 200
```
![copy actor](/images/homework9/copy_actor.png "copy actor")

4) Восстановим данные в другую таблицу
```
CREATE TABLE actor_new (LIKE actor INCLUDING ALL);
CREATE TABLE
\copy actor_new from '/tmp/actor.sql';
COPY 200
```
![actor_new](/images/homework9/actor_new.png "actor_new")

5) С помощью pg_dump делаем бэкап двух таблиц (city, country)
```
pg_dump -U postgres -t country -t country_country_id_seq -t city -t city_city_id_seq --create -Fc > /tmp/backup_dump.gz
```

6) Восстановим с помощью pg_restore таблицу country:
```
createdb -U postgres dvdrental && pg_restore -U postgres --schema public -d dvdrental -t country -t country_country_id_seq /tmp/backup_dump.gz
```
![country](/images/homework9/country.png "country")

