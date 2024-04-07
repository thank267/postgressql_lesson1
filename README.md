# Уровень изоляции Read Сommitted 

При данном уровне изоляции мы не видим во второй сессии добавленную строчку  insert into persons(first_name, second_name) values('sergey', 'sergeev');,
т.к. транзакция не закомичена в первой сессии и грязное чтение невозможно в Postgresql. После коммита транзакции в первой сессии,
мы увидели добавленную строчку в первой сессии при повторном селект, т.к. non-repeatable read возможно при данном уровне изоляции транзакций

# Уровень изоляции Repeatable Read

При данном уровне изоляции мы также не видим во второй сессии добавленную строчку  insert into persons(first_name, second_name) values('sveta', 'svetova');,
т.к. транзакция не закомичена в первой сессии и грязное чтение невозможно в Postgresql.

После того, как мы сделали коммит во второй сессии, мы по прежнему не видим закомиченную запись в первой сессии, т.к.phantom read не предусмотрено в postgres
при данном уровне изоляции. При завершении транзакции во второй секции, очередной select * from persons дает ожидаемый результат -
все сроки появились в запросе