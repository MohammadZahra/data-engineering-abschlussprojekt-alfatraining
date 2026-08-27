-- Run the complete Bank Card ETL process.

USE STG_BankCard;
GO


-- Load all dimensions first.

EXEC dbo.usp_Load_Dim_Customer;
GO

EXEC dbo.usp_Load_Dim_Card;
GO

EXEC dbo.usp_Load_Dim_Merchant;
GO

EXEC dbo.usp_Load_Dim_Time;
GO


-- Load the Transaction fact table after all dimensions.

EXEC dbo.usp_Load_Fact_Transaction;
GO