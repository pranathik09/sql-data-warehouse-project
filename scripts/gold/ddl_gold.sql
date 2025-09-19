IF OBJECT_ID('glayer.dim_customer', 'V') IS NOT NULL
	DROP VIEW glayer.dim_customer;
GO
CREATE VIEW glayer.dim_customer AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_materialstatus AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
	FROM slayer.crm_cust_info ci
	LEFT JOIN slayer.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
	LEFT JOIN slayer.erp_loc_a101 la
	ON ci.cst_key = la.cid


IF OBJECT_ID('glayer.dim_products', 'V') IS NOT NULL
	DROP VIEW glayer.dim_products;
GO
CREATE VIEW glayer.dim_products AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY pm.prd_start_dt, pm.prd_key) AS product_key,
	pm.prd_id AS product_id,
	pm.prd_key AS product_number,
	pm.prd_nm AS product_name,
	pm.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pm.prd_cost AS cost,
	pm.prd_line AS product_line,
	pm.prd_start_dt AS start_date
FROM slayer.crm_prd_info pm
LEFT JOIN slayer.erp_px_cat_g1v2 pc
ON pm.cat_id = pc.id
WHERE prd_end_dt IS NULL



IF OBJECT_ID('glayer.fact_sales', 'V') IS NOT NULL
	DROP VIEW glayer.fact_sales;
GO
CREATE VIEW glayer.fact_sales AS
SELECT 
sd.sls_order_num AS order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM slayer.crm_sales_details sd
LEFT JOIN glayer.dim_products pr
ON sd.sls_product_key = pr.product_number
LEFT JOIN glayer.dim_customer cu
ON sd.sls_cust_id = cu.customer_id
