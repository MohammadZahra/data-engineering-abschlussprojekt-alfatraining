-- Create the Bank Card Data Warehouse.

CREATE DATABASE BankCardDWH;
GO

USE BankCardDWH;
GO


-- Create the DWH schema.

CREATE SCHEMA dwh;
GO


-- Create the Time dimension.

CREATE TABLE dwh.[Time]
(
    TimeID     INT NOT NULL,
    [Day]      DATE NOT NULL,
    [Week]     TINYINT NOT NULL,
    [Month]    TINYINT NOT NULL,
    [Quarter]  TINYINT NOT NULL,
    [Year]     SMALLINT NOT NULL,

    CONSTRAINT PK_Time
        PRIMARY KEY (TimeID),

    CONSTRAINT UQ_Time_Day
        UNIQUE ([Day])
);
GO


-- Create the Customer dimension.

CREATE TABLE dwh.Customer
(
    CustomerID        INT IDENTITY(1,1) NOT NULL,
    SourceCustomerID  INT NOT NULL,
    CustomerName      NVARCHAR(101) NOT NULL,
    BirthDate         DATE NOT NULL,
    CustomerCity      NVARCHAR(100) NOT NULL,
    CustomerRegion    NVARCHAR(100) NULL,
    CustomerCountry   NVARCHAR(60) NOT NULL,
    ValidFrom         DATETIME NOT NULL,
    ValidTo           DATETIME NULL,

    CONSTRAINT PK_Customer
        PRIMARY KEY (CustomerID)
);
GO


-- Create the Card dimension.

CREATE TABLE dwh.Card
(
    CardID            INT IDENTITY(1,1) NOT NULL,
    SourceCardNumber  NVARCHAR(19) NOT NULL,
    CardType          NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_Card
        PRIMARY KEY (CardID),

    CONSTRAINT UQ_Card_SourceCardNumber
        UNIQUE (SourceCardNumber)
);
GO


-- Create the Merchant dimension.

CREATE TABLE dwh.Merchant
(
    MerchantID          INT IDENTITY(1,1) NOT NULL,
    SourceMerchantID    INT NOT NULL,
    MerchantName        NVARCHAR(100) NOT NULL,
    MerchantCategory    NVARCHAR(50) NOT NULL,
    MerchantStreet      NVARCHAR(100) NULL,
    MerchantPostalCode  NVARCHAR(20) NULL,
    MerchantCity        NVARCHAR(100) NOT NULL,
    MerchantRegion      NVARCHAR(100) NULL,
    MerchantCountry     NVARCHAR(60) NOT NULL,
    ValidFrom           DATETIME NOT NULL,
    ValidTo             DATETIME NULL,

    CONSTRAINT PK_Merchant
        PRIMARY KEY (MerchantID)
);
GO


-- Create the Transaction fact table.

CREATE TABLE dwh.[Transaction]
(
    TransactionID        BIGINT NOT NULL,
    TimeID               INT NOT NULL,
    CardID               INT NOT NULL,
    CustomerID           INT NOT NULL,
    MerchantID           INT NOT NULL,
    TransactionAmountEUR DECIMAL(12,2) NOT NULL,

    CONSTRAINT PK_Transaction
        PRIMARY KEY (TransactionID),

    CONSTRAINT FK_Transaction_Time
        FOREIGN KEY (TimeID)
        REFERENCES dwh.[Time](TimeID),

    CONSTRAINT FK_Transaction_Card
        FOREIGN KEY (CardID)
        REFERENCES dwh.Card(CardID),

    CONSTRAINT FK_Transaction_Customer
        FOREIGN KEY (CustomerID)
        REFERENCES dwh.Customer(CustomerID),

    CONSTRAINT FK_Transaction_Merchant
        FOREIGN KEY (MerchantID)
        REFERENCES dwh.Merchant(MerchantID)
);
GO


------------------------------------------
------------------------------------------

-- Verify DWH tables were created.

USE BankCardDWH;
GO

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dwh'
ORDER BY TABLE_NAME;

