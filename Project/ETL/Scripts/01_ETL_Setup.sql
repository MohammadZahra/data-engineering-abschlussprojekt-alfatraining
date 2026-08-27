-- Create the ETL staging database and control table.

IF DB_ID('STG_BankCard') IS NULL
BEGIN
    CREATE DATABASE STG_BankCard;
END;
GO

USE STG_BankCard;
GO

IF OBJECT_ID('dbo.control_table', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.control_table
    (
        FactTableName      VARCHAR(100) NOT NULL PRIMARY KEY,
        Last_loading_Date  DATETIME2(0) NOT NULL
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.control_table
    WHERE FactTableName = 'Transaction'
)
BEGIN
    INSERT INTO dbo.control_table
        (FactTableName, Last_loading_Date)
    VALUES
        ('Transaction', '19000101');
END;
GO

SELECT *
FROM dbo.control_table;
GO