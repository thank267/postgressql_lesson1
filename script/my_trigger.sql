SET search_path = pract_functions, publ;

-- т.к. данные были занесены в мастер таблицы дл создания витрины good_sum_mart,
-- необходимо обновить агрегационные данные для каждого goods_id в запросах INSERT, UPDATE. DELETE
CREATE PROCEDURE insert_no_exists(in id integer)
AS
$$
BEGIN

    INSERT INTO good_sum_mart (good_name, sum_sale)
    SELECT G.good_name, sum(G.good_price * S.sales_qty)
    FROM goods G
             LEFT JOIN good_sum_mart GSM ON GSM.good_name = G.good_name
             INNER JOIN sales S ON S.good_id = G.goods_id

    where G.goods_id = id and GSM.good_name IS NULL
    GROUP BY G.good_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_showcase()
RETURNS trigger AS
$func$
BEGIN
    CASE TG_OP

        WHEN 'INSERT'
            THEN
                CALL insert_no_exists(NEW.good_id);

                UPDATE good_sum_mart GSM
                SET sum_sale = sum_sale + NEW.sales_qty * G.good_price
                    from goods G
                where G.goods_id =NEW.good_id and GSM.good_name=G.good_name;

                RETURN NEW;

        WHEN 'UPDATE'
            THEN
                CALL insert_no_exists(NEW.good_id);

                CALL insert_no_exists(OLD.good_id);

                UPDATE good_sum_mart GSM
                SET sum_sale = sum_sale - OLD.sales_qty * G.good_price
                    from goods G
                where G.goods_id = OLD.good_id and GSM.good_name=G.good_name;

                UPDATE good_sum_mart GSM
                SET sum_sale = sum_sale + NEW.sales_qty * G.good_price
                    from goods G
                where G.goods_id = NEW.good_id and GSM.good_name=G.good_name;

                RETURN NEW;

        WHEN 'DELETE'
            THEN
                CALL insert_no_exists(OLD.good_id);

                UPDATE good_sum_mart GSM
                SET sum_sale = sum_sale - OLD.sales_qty * G.good_price
                    from goods G
                where G.goods_id = OLD.good_id and GSM.good_name=G.good_name;

                RETURN OLD;

    END CASE;

END
$func$
LANGUAGE plpgsql
    SET search_path = pract_functions, publ;


CREATE OR REPLACE TRIGGER insert_showcase
    BEFORE INSERT OR UPDATE OR DELETE ON sales
    FOR EACH ROW
    EXECUTE FUNCTION insert_showcase();


