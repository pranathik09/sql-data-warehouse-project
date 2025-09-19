EXEC slayer.load_slayer;

CREATE OR ALTER PROCEDURE slayer.load_slayer AS
BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME,@batch_start_time DATETIME,@batch_end_time DATETIME
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '======================================================================================';
		PRINT 'Loading slayer Layer' ;
		PRINT '======================================================================================';

		PRINT '--------------------------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------------------------------------------------------';
	
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: slayer.crm_cust_info'
		TRUNCATE TABLE slayer.crm_cust_info
		PRINT '>> Inserting Data Into: slayer.crm_cust_info'

		INSERT INTO slayer.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_materialstatus,
			cst_gndr,
			cst_create_date)
		SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_materialstatus)) = 'S' THEN 'Single'
			 WHEN UPPER(TRIM(cst_materialstatus)) = 'M' THEN 'Married'
			 ELSE 'n/a'
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
		FROM (
		SELECT *,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM blayer.crm_cust_info
		)t WHERE flag_last = 1;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: slayer.crm_prd_info'
		TRUNCATE TABLE slayer.crm_prd_info
		PRINT '>> Inserting Data Into: slayer.crm_prd_info'

		INSERT INTO slayer.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
				 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
				 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
				 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt
		FROM blayer.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: slayer.crm_sales_details'
		TRUNCATE TABLE slayer.crm_sales_details
		PRINT '>> Inserting Data Into: slayer.crm_sales_details'

		INSERT INTO slayer.crm_sales_details(
			sls_order_num,
			sls_product_key,
			sls_cust_id ,
			sls_order_dt ,
			sls_ship_dt ,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price 
		)
		SELECT
			sls_order_num,
			sls_product_key,
			sls_cust_id,
			CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
			CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,
			CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
				 ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
				 ELSE sls_price
			END AS sls_price
		FROM blayer.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: slayer.erp_cust_az12'
		TRUNCATE TABLE slayer.erp_cust_az12
		PRINT '>> Inserting Data Into: slayer.erp_cust_az12'


		INSERT INTO slayer.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4 , LEN(cid))
				 ELSE cid
			END AS cid,
			CASE WHEN bdate > GETDATE() THEN NULL
				 ELSE bdate
			END AS bdate,
			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'n/a'
			END AS gen
		FROM blayer.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: slayer.erp_loc_a101'
		TRUNCATE TABLE slayer.erp_loc_a101
		PRINT '>> Inserting Data Into: slayer.erp_loc_a101'

		INSERT INTO slayer.erp_loc_a101(
			cid,
			cntry
		)
		SELECT
			REPLACE(cid, '-', '') AS cid,
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				 ELSE TRIM(cntry)
			END AS cntry
		FROM blayer.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: slayer.erp_px_cat_g1v2'
		TRUNCATE TABLE slayer.erp_px_cat_g1v2
		PRINT '>> Inserting Data Into: slayer.erp_px_cat_g1v2'

		INSERT INTO slayer.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM blayer.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ----------------';

		SET @batch_end_time = GETDATE();
		PRINT '======================================================================================';
		PRINT 'blayer Layer Completed' ;
		PRINT ' -Total Load Duration: ' + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'seconds';
		PRINT '======================================================================================';
		END TRY
		BEGIN CATCH
			PRINT '======================================================================================';
			PRINT 'Error Occured During Loading blayer Layer' ;
			PRINT 'Error Message' + ERROR_MESSAGE();
			PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'Erroe State' + CAST(ERROR_STATE() AS NVARCHAR);
			PRINT '======================================================================================';

		END CATCH
END

