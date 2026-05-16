create or alter procedure bronze.load_bronze as 
begin
	declare @start_time as datetime , @end_time as datetime , @batch_start as datetime , @batch_end as datetime;
	begin try
		set @batch_start = GETDATE();
		print('================================================');
		print('Loading Bronze Layer');
		print('================================================');


		print('-------------------------------------------------');
		print('Loading CRM Tables');
		print('-------------------------------------------------');
		
		set @start_time = getdate();
		print('>> Truncting Table: bronze.crm_cust_info');
		truncate table bronze.crm_cust_info;
		print('>> Inserting Data Into: bronze.crm_cust_info');
		bulk insert bronze.crm_cust_info
		from 'C:\Users\user\Documents\DWH Project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with(
			firstrow =2 ,
			fieldterminator = ',',
			tablock
		);

		set @end_time = getdate();
		print '>> Load Duration: '+ cast(datediff(second,@start_time , @end_time) as nvarchar) + ' Seconds'; 
		print '--------'

		set @start_time = getdate();
		print('>> Truncting Table: bronze.crm_prd_info');
		truncate table bronze.crm_prd_info;
		print('>> Inserting Data Into: bronze.crm_prd_info');
		bulk insert bronze.crm_prd_info
		from 'C:\Users\user\Documents\DWH Project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with(
			firstrow =2 ,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: '+ cast(datediff(second,@start_time , @end_time) as nvarchar) + ' Seconds'; 
		print '--------'


		set @start_time = getdate();
		print('>> Truncting Table: bronze.crm_sales_details');

		truncate table bronze.crm_sales_details;
		print('>> Inserting Data Into: crm_sales_details');
		bulk insert bronze.crm_sales_details
		from 'C:\Users\user\Documents\DWH Project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with(
			firstrow =2 ,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: '+ cast(datediff(second,@start_time , @end_time) as nvarchar) + ' Seconds'; 
		print '--------'

		print('-------------------------------------------------');
		print('Loading ERP Tables');
		print('-------------------------------------------------');
		print('>> Truncting Table: bronze.erp_cust_az12');


		set @start_time = getdate();
		truncate table bronze.erp_cust_az12;
		print('>> Inserting Data Into: bronze.erp_cust_az12');

		bulk insert bronze.erp_cust_az12
		from 'C:\Users\user\Documents\DWH Project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with(
			firstrow =2 ,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: '+ cast(datediff(second,@start_time , @end_time) as nvarchar) + ' Seconds'; 
		print '--------'

		set @start_time = getdate();
		print('>> Truncting Table: bronze.erp_loc_a101');
		truncate table bronze.erp_loc_a101;
		print('>> Inserting Data Into: bronze.erp_loc_a101');

		bulk insert bronze.erp_loc_a101
		from 'C:\Users\user\Documents\DWH Project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		with(
			firstrow =2 ,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: '+ cast(datediff(second,@start_time , @end_time) as nvarchar) + ' Seconds'; 
		print '--------'

		set @start_time = getdate();
		print('>> Truncting Table: bronze.erp_px_cat_g1v2');
		truncate table bronze.erp_px_cat_g1v2;
		print('>> Inserting Data Into: bronze.erp_px_cat_g1v2');

		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Users\user\Documents\DWH Project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		with(
			firstrow =2 ,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '>> Load Duration: '+ cast(datediff(second,@start_time , @end_time) as nvarchar) + ' Seconds'; 
		print '--------';

		set @batch_end =GETDATE();
		print '=================================================';
		print 'Loading Bronze Layer is Completed';
		print 'Total Duration: ' + cast(datediff(second , @batch_start , @batch_end) as nvarchar) + ' Seconds';
		print '=================================================';
	end try
	begin catch
		print('===================================================');
		print('Error Ocurred during Loading Bronze Layer');
		print('Error MSG') + error_message(); 
		print('Error NUM') + cast (error_number() as nvarchar);
		print('Error STATE') + cast (error_state() as nvarchar); 
		print('===================================================');
	end catch

end

