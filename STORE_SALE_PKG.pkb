create or replace PACKAGE BODY store_sale_pkg AS 


PROCEDURE sp_store_order_create (
    p_store_id  tbl_dim_stores.store_id%TYPE,
    p_order_id  tbl_store_order.id%TYPE DEFAULT NULL,
    p_status    tbl_store_order.status%TYPE,
    p_product_id  tbl_dim_products.id%TYPE,
    p_quantity    tbl_store_order_item.quantity%TYPE
) IS 
v_order_id_count number := 0;
v_pk number;
BEGIN

SELECT COUNT(*) INTO v_order_id_count
FROM tbl_store_order 
WHERE ID = p_order_id;

IF v_order_id_count = 0
THEN
    INSERT INTO tbl_store_order (
        store_id,
        status,
        order_date
    ) VALUES (
        p_store_id,
        p_status,
        sysdate 
    ) returning id into v_pk;
 END IF;
    
     sp_store_order_item_create ( CASE WHEN v_pk IS NOT NULL THEN v_pk ELSE p_order_id END,p_product_id,p_quantity);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error raised'||SQLERRM);
END; 

PROCEDURE sp_store_order_item_create (
    p_order_id    tbl_store_order.id%TYPE,
    p_product_id  tbl_dim_products.id%TYPE,
    p_quantity    tbl_store_order_item.quantity%TYPE
) IS

    v_order_amount  NUMBER(10, 2) := 0;
    v_rowcount      NUMBER := 0;
    negative_quantity_entered EXCEPTION;
    PRAGMA exception_init ( negative_quantity_entered, -60 );
BEGIN
    IF p_quantity < 0 THEN
        RAISE negative_quantity_entered;
    END IF;
    MERGE INTO tbl_store_order_item oi
    USING (
              SELECT
                  p_order_id          order_id,
                  id,
                  p_quantity          quantity,
                  price * p_quantity  amount
              FROM
                  tbl_dim_products
              WHERE
                  id = p_product_id
          )
    p ON ( oi.product_id = p.id
           AND oi.order_id = p.order_id )
    WHEN MATCHED THEN UPDATE
    SET oi.quantity = oi.quantity + p.quantity,
        oi.amount = oi.amount + p.amount,
        oi.update_date = sysdate
    WHEN NOT MATCHED THEN
    INSERT (
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.amount )
    VALUES
        ( p.order_id,
          p.id,
          p.quantity,
          p.amount );
--dbms_output.put_line('Message');
    v_rowcount := SQL%rowcount;
    IF v_rowcount > 0 THEN
        SELECT
            SUM(amount)
        INTO v_order_amount
        FROM
            tbl_store_order_item
        WHERE
            order_id = p_order_id;

        dbms_output.put_line(to_char(v_order_amount)
                             || 'order_amount');
        UPDATE tbl_store_order
        SET
            order_amount = v_order_amount
        WHERE
            id = p_order_id;

    END IF;

    COMMIT;
EXCEPTION 
WHEN negative_quantity_entered THEN
   
     DBMS_OUTPUT.PUT_LINE ('Negative quintity entered.');
WHEN  OTHERS THEN
        dbms_output.put_line('Error raised'||SQLERRM);

END;

    PROCEDURE sp_update_product (
        p_product_id  tbl_dim_products.id%TYPE := NULL,
        p_vendor_id   tbl_dim_vendor.vendor_id%TYPE,
        p_procent     NUMBER
    ) AS

        r_product    tbl_dim_products%rowtype;
        v_new_price  NUMBER(10, 2);
        CURSOR c_product (
            p_product_id  tbl_dim_products.id%TYPE := NULL,
            p_vendor_id   tbl_dim_vendor.vendor_id%TYPE
        ) IS
        SELECT
            *
        FROM
            tbl_dim_products
        WHERE
                vendor_id = p_vendor_id
            AND id = nvl(p_product_id, id)
        FOR UPDATE OF price;

    BEGIN
        OPEN c_product(p_product_id, p_vendor_id);
        LOOP
            FETCH c_product INTO r_product;
            EXIT WHEN c_product%notfound;
            v_new_price := r_product.price / 100 * p_procent;
            dbms_output.put_line(r_product.name
                                 || ':'
                                 || r_product.price
                                 || 'Price incrise: '
                                 || to_char(v_new_price));

            UPDATE tbl_dim_products
            SET
                price = price + v_new_price--price/100*p_procent
            WHERE
                    vendor_id = p_vendor_id
                AND id = r_product.id;

        END LOOP;

        CLOSE c_product;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error');
    END sp_update_product;



END
store_sale_pkg;