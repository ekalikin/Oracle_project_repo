create or replace PACKAGE STORE_SALE_PKG AS 

PROCEDURE sp_store_order_item_create 
(p_order_id tbl_store_order.ID%TYPE,
p_product_id tbl_dim_products.id%TYPE,
p_quantity tbl_store_order_item.quantity%TYPE
);

PROCEDURE sp_store_order_create (
    p_store_id  tbl_dim_stores.store_id%TYPE,
    p_order_id  tbl_store_order.id%TYPE DEFAULT NULL,
    p_status    tbl_store_order.status%TYPE,
    p_product_id  tbl_dim_products.id%TYPE,
    p_quantity    tbl_store_order_item.quantity%TYPE);

PROCEDURE sp_update_product
( p_product_id tbl_dim_products.ID%TYPE := NULL,
  p_vendor_id tbl_dim_vendor.vendor_id%TYPE,
  p_procent NUMBER);

END STORE_SALE_PKG;