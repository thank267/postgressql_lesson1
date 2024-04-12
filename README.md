# Установка PostgreSQL

Для установки использовал docker-compose файл:
[docker-compose файл](/docker_compose_files/postgresql-otus-docker-compose.yml)

После поднятия контейнера
![контейнер postgresql](/images/docker_postgresql.png "контейнер postgresql")

создался смапленый в директорию volume
![volume postgresql](/images/docker_volume.png "volume postgresql")

в директории /var/lib/postgres логично появились данные postgres
![данные postgresql](/images/var_lib_postgres.png "данные postgresql")

сервер postgresql виден из внешнего мира:
![postgresql коннект](/images/postgresql_connect.png "postgresql коннект")

После удаления контейнера и volume и его повторного поднятия данные в тестовой таблице сохранились