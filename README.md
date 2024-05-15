# Нагрузочное тестирование и тюнинг PostgreSQL

1) Устанавливаем дистрибутив Postgresql 15.7 на ноутбук с Windows 10. Смотрим дефолтную производительность
```
иницилизируем pgbench
c:\Program Files\PostgreSQL\15\bin>pgbench -i -U postgres postgres


даем нагрузку
pgbench -c 50 -j 2 -P 10 -T 60 -U postgres postgres
pgbench (15.7)
starting vacuum...end.
progress: 10.0 s, 322.8 tps, lat 108.075 ms stddev 420.158, 0 failed
progress: 20.0 s, 1781.5 tps, lat 28.389 ms stddev 38.009, 0 failed
progress: 30.0 s, 948.8 tps, lat 43.848 ms stddev 149.358, 0 failed
progress: 40.0 s, 1376.8 tps, lat 42.407 ms stddev 191.050, 0 failed
progress: 50.0 s, 1775.9 tps, lat 28.149 ms stddev 34.976, 0 failed
progress: 60.0 s, 874.1 tps, lat 57.171 ms stddev 266.812, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 70863
number of failed transactions: 0 (0.000%)
latency average = 40.334 ms
latency stddev = 167.007 ms
initial connection time = 2878.450 ms
tps = 1238.732097 (without initial connection time)
```
3) настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины
4) нагрузить кластер через утилиту через утилиту pgbench
5) написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему

используем pgtune
```
# DB Version: 15
# OS Type: windows
# DB Type: web
# Total Memory (RAM): 16 GB
# CPUs num: 8
# Data Storage: ssd

max_connections = 200
shared_buffers = 4GB
effective_cache_size = 12GB
maintenance_work_mem = 1GB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
work_mem = 5242kB
huge_pages = off
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

от себя добавим, т.к. сохранность данных не важна
synchronous_commit = off
```

даем нагрузку
```
pgbench (15.7)
starting vacuum...end.
progress: 10.0 s, 1715.9 tps, lat 20.800 ms stddev 26.918, 0 failed
progress: 20.0 s, 2355.4 tps, lat 21.220 ms stddev 27.679, 0 failed
progress: 30.0 s, 2052.2 tps, lat 24.315 ms stddev 57.252, 0 failed
progress: 40.0 s, 2326.2 tps, lat 21.507 ms stddev 29.316, 0 failed
progress: 50.0 s, 2222.4 tps, lat 22.453 ms stddev 34.716, 0 failed
progress: 60.0 s, 2259.2 tps, lat 22.192 ms stddev 33.395, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 129371
number of failed transactions: 0 (0.000%)
latency average = 22.098 ms
latency stddev = 36.244 ms
initial connection time = 2842.724 ms
tps = 2261.318513 (without initial connection time)
```
Было tps = 1238.732097, стало tps = 2261.318513



