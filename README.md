# Установка и настройка Postgresql

Т.к. работаю в докере для windows пришлось сразу создать внешний диск и приаттачить его создаваемому образу с помощью команд:
```
1) docker pull ubuntu:22.04
2) docker volume create --driver local --opt type=none --opt device=c:/var/lib/postgres2 --opt o=bind disk2
   disk2
3) docker run --name otus --mount source=disk2,target=/opt/disk2 -it ubuntu:22.04
```

Далее на чистую ubuntu 22.04 ставлю Postgresql 15.6:
```
4) apt update
5) apt upgrade
6) apt install -y postgresql-common
7) apt install gnupg
8) apt install gnupg2
9) apt install gnupg1
10) /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
11) apt update
12) apt -y install postgresql-15
```

Установили, смотрим результат
![контейнер Ubuntu 22.04 c postgresql 15.6](/images/homework3/install.png "контейнер Ubuntu 22.04 c postgresql 15.6")

Запускаем PG и создаем тестовую таблицу
```
13) /etc/init.d/postgresql start
14) sudo -u postgres pg_lsclusters
```
![Кластер запущен](/images/homework3/clusterUp.png "Кластер запущен")
```
16) sudo -u postgres psql
17) create table test(c1 text);
18) insert into test values('1');
19) \q
```

Останавливаем кластер и переносим директорию на внешний диск
```
21) sudo -u postgres pg_ctlcluster 15 main stop
22) chown -R postgres:postgres /opt/disk2
23) mv /var/lib/postgresql/15 /opt/disk2
```
![Внешний диск](/images/homework3/external_disk.png "Внешний диск")
![Примонтированный диск](/images/homework3/mounted_disk.png "Примонтированный диск")

Повторный запуск кластера Postgresql вызывает естественную ошибку
```
24) sudo -u postgres pg_ctlcluster 15 main start 
25) Error: /var/lib/postgresql/15/main is not accessible or does not exist
```

Для исправления ситуации правим файл /etc/postgresql/15/main/postgresql.conf
```
26) data_directory = '/opt/disk2/15/main'
27) /etc/init.d/postgresql start
28) select * from test;
```

![Все взлетело](/images/homework3/finish.png "Все взлетело")