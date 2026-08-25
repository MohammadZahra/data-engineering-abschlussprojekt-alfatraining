-- Create staging schema and raw-data tables.

USE BankCardDB;
GO

-- Create staging schema.
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg AUTHORIZATION dbo');
END;
GO


-- Create Customer staging table.
CREATE TABLE stg.Customer
(
    CustomerID  NVARCHAR(255) NULL,
    FirstName   NVARCHAR(255) NULL,
    LastName    NVARCHAR(255) NULL,
    BirthDate   NVARCHAR(255) NULL,
    Email       NVARCHAR(255) NULL,
    Phone       NVARCHAR(255) NULL,
    Street      NVARCHAR(255) NULL,
    PostalCode  NVARCHAR(255) NULL,
    City        NVARCHAR(255) NULL,
    Region      NVARCHAR(255) NULL,
    Country     NVARCHAR(255) NULL
);
GO


-- Create Account staging table.
CREATE TABLE stg.Account
(
    AccountNumber  NVARCHAR(255) NULL,
    Type           NVARCHAR(255) NULL,
    Currency       NVARCHAR(255) NULL,
    Status         NVARCHAR(255) NULL,
    OpeningDate    NVARCHAR(255) NULL
);
GO


-- Create Card staging table.
CREATE TABLE stg.Card
(
    CardNumber     NVARCHAR(255) NULL,
    ExpiryDate     NVARCHAR(255) NULL,
    Type           NVARCHAR(255) NULL,
    Status         NVARCHAR(255) NULL,
    CustomerID     NVARCHAR(255) NULL,
    AccountNumber  NVARCHAR(255) NULL
);
GO


-- Create Transaction staging table.
CREATE TABLE stg.[Transaction]
(
    TransactionID  NVARCHAR(255) NULL,
    [Date]         NVARCHAR(255) NULL,
    [Time]         NVARCHAR(255) NULL,
    Status         NVARCHAR(255) NULL,
    Type           NVARCHAR(255) NULL,
    Currency       NVARCHAR(255) NULL,
    Amount         NVARCHAR(255) NULL,
    CardNumber     NVARCHAR(255) NULL,
    MerchantID     NVARCHAR(255) NULL
);
GO


-- Create Merchant staging table.
CREATE TABLE stg.Merchant
(
    MerchantID          NVARCHAR(255) NULL,
    Name                NVARCHAR(255) NULL,
    Street              NVARCHAR(255) NULL,
    PostalCode          NVARCHAR(255) NULL,
    City                NVARCHAR(255) NULL,
    Region              NVARCHAR(255) NULL,
    Country             NVARCHAR(255) NULL,
    MerchantCategoryID  NVARCHAR(255) NULL
);
GO


-- Create MerchantCategory staging table.
CREATE TABLE stg.MerchantCategory
(
    MerchantCategoryID  NVARCHAR(255) NULL,
    CategoryName        NVARCHAR(255) NULL,
    Description         NVARCHAR(1000) NULL
);
GO


-- Create account ownership staging table.
CREATE TABLE stg.AccountOwnership
(
    CustomerID     NVARCHAR(255) NULL,
    AccountNumber  NVARCHAR(255) NULL,
    Role           NVARCHAR(255) NULL
);
GO