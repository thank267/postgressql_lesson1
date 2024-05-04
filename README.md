# Работа с базами данных, пользователями и правами

1) Для установки использовал docker-compose файл:
   [docker-compose файл](/docker_compose_files/postgresql-14-otus-docker-compose.yml)

2) Коннекчусь к кластеру 
```
psql -U postgres
```
3) Создаю базу testdb
```
CREATE DATABASE testdb;
\c testdb;
```
4) Коннекчусь к ней
```
\c testdb;
```
5) Создаю схему testnm
```
CREATE SCHEMA testnm;
```
6) Создаю таблицу t1. Т.к. я привык работать со схемами и не видел "шпаргалки", то сразу создал таблицу с префиксом
```
CREATE TABLE testnm.t1( c1 INT);
```
7) Заполняю таблицу тестовыми данными
```
INSERT INTO testnm.t1 (c1) VALUES (1);
```
8) Создаю роль readonly
```
CREATE ROLE readonly;
```
9) Даю право на логин
```
ALTER ROLE "readonly" WITH LOGIN;
```
10) Даю право на использование схемы testnm
```
GRAND USAGE ON SCHEMA testnm TO "readonly";
```
11) Даю право на SELECT всех таблиц в testnm
```
GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO "readonly";
```
12) Создаю пользователя testread с паролем test123
```
create user testread with encrypted password 'test123';
```
13) Маплю пользователя и роль
```
GRANT readonly TO testread;
```
14) Захожу под новым пользователем в базу
```
\c testdb testread
```
15) Запрашиваю данные из созданной таблицы
```
select * from testnm.t1;
```
16-21. Т.к. создавал таблицу с префиксом у меня все завелось
22) возвращаюсь в кластер под пользователем postgres
```
\c testdb postgres
```
23) удаляю таблицу
```
DROP TABLE testnm.t1;
```
24) Повторно создаю таблицу с указанием схемы
```
CREATE TABLE testnm.t1( c1 INT);
```
25) Заполняю данными
```
INSERT INTO testnm.t1 (c1) VALUES (1);
```
26) Захожу под пользователем testread
```
\c testdb testread
```
27) Читаю данные
```
select * from testnm.t1; 
```
28) Получаю ошибку
```
ERROR:  permission denied for table t1; 
```
29) Хоть раздавали права на все таблицы, новой таблицы (шаг 24) когда раздавали права (шаг 11) тогда не существовало.
30) Добавляем привилегии по умолчанию под пользователем postgres
```
\c testdb postgres
ALTER default privileges in SCHEMA testnm grant SELECT on TABLES to readonly;
\c testdb testread
```
31) Читаем данные
```
select * from testnm.t1; 
```
32) Получаем ту же ошибку потому что до выполнения команды с раздачей привилегий (шаг 30) таблица существовала (шаг 24)
```
ERROR:  permission denied for table t1; 
```
33) Исправляем - переконнекчиваюсь под postgres и делаю 
```
\c testdb postgres
GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO "readonly";
```
Можно проверить
```
SELECT * FROM information_schema.role_table_grants WHERE grantee = 'readonly';) 
```
34) Выбираю данные 
```
select * from testnm.t1; 
```
35-36. Ура получилось
![ура!](/images/homework4/allright.png "ура!")

37) Пробуем с новой таблицей
```
create table t2(c1 integer);
insert into t2 values (2);
```
38) Все получилось. Т.к. схема не указана и мы создали t2 в public

39-40. Забываем про public и меняем search path
```
\c testdb postgres;
REVOKE CREATE on SCHEMA public FROM public;
REVOKE ALL on DATABASE testdb FROM public;
GRANT CONNECT ON DATABASE testdb TO readonly;
ALTER USER 'testread' set SEARCH_PATH = 'testnm';
\c testdb testread;
```
41) делаем новую таблицу t3 и заполняем данными
```
create table t3(c1 integer);
insert into t2 values (2);
```
42) все получилось
![все получилось](/images/homework4/allright2.png "все получилось")