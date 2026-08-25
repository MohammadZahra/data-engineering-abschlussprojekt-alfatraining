-- Create normalized Business Database tables.

USE BankCardDB;
GO


-- Create Customer table.
CREATE TABLE dbo.Customer
(
    CustomerID  INT IDENTITY(1,1) NOT NULL,
    FirstName   NVARCHAR(50) NOT NULL,
    LastName    NVARCHAR(50) NOT NULL,
    BirthDate   DATE NOT NULL,
    Email       NVARCHAR(100) NULL,
    Phone       NVARCHAR(25) NULL,
    Street      NVARCHAR(100) NOT NULL,
    PostalCode  NVARCHAR(20) NOT NULL,
    City        NVARCHAR(100) NOT NULL,
    Region      NVARCHAR(100) NULL,
    Country     NVARCHAR(60) NOT NULL,

    CONSTRAINT PK_Customer
        PRIMARY KEY (CustomerID)
);
GO


-- Create Account table.
CREATE TABLE dbo.Account
(
    AccountNumber  NVARCHAR(34) NOT NULL,
    Type           NVARCHAR(20) NOT NULL,
    Currency       CHAR(3) NOT NULL,
    Status         NVARCHAR(20) NOT NULL,
    OpeningDate    DATE NOT NULL,

    CONSTRAINT PK_Account
        PRIMARY KEY (AccountNumber)
);
GO


-- Create MerchantCategory table.
CREATE TABLE dbo.MerchantCategory
(
    MerchantCategoryID  INT IDENTITY(1,1) NOT NULL,
    CategoryName        NVARCHAR(50) NOT NULL,
    Description         NVARCHAR(255) NULL,

    CONSTRAINT PK_MerchantCategory
        PRIMARY KEY (MerchantCategoryID),

    CONSTRAINT UQ_MerchantCategory_CategoryName
        UNIQUE (CategoryName)
);
GO


-- Create ownership relation.
CREATE TABLE dbo.AccountOwnership
(
    CustomerID     INT NOT NULL,
    AccountNumber  NVARCHAR(34) NOT NULL,
    Role           NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_AccountOwnership
        PRIMARY KEY (CustomerID, AccountNumber),

    CONSTRAINT FK_AccountOwnership_Customer
        FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customer(CustomerID),

    CONSTRAINT FK_AccountOwnership_Account
        FOREIGN KEY (AccountNumber)
        REFERENCES dbo.Account(AccountNumber)
);
GO


-- Create Card table.
CREATE TABLE dbo.Card
(
    CardNumber     NVARCHAR(19) NOT NULL,
    ExpiryDate     DATE NOT NULL,
    Type           NVARCHAR(20) NOT NULL,
    Status         NVARCHAR(20) NOT NULL,
    CustomerID     INT NOT NULL,
    AccountNumber  NVARCHAR(34) NOT NULL,

    CONSTRAINT PK_Card
        PRIMARY KEY (CardNumber),

    CONSTRAINT FK_Card_Customer
        FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customer(CustomerID),

    CONSTRAINT FK_Card_Account
        FOREIGN KEY (AccountNumber)
        REFERENCES dbo.Account(AccountNumber)
);
GO


-- Create Merchant table.
CREATE TABLE dbo.Merchant
(
    MerchantID          INT IDENTITY(1,1) NOT NULL,
    Name                NVARCHAR(100) NOT NULL,
    Street              NVARCHAR(100) NULL,
    PostalCode          NVARCHAR(20) NULL,
    City                NVARCHAR(100) NOT NULL,
    Region              NVARCHAR(100) NULL,
    Country             NVARCHAR(60) NOT NULL,
    MerchantCategoryID  INT NOT NULL,

    CONSTRAINT PK_Merchant
        PRIMARY KEY (MerchantID),

    CONSTRAINT FK_Merchant_MerchantCategory
        FOREIGN KEY (MerchantCategoryID)
        REFERENCES dbo.MerchantCategory(MerchantCategoryID)
);
GO


-- Create Transaction table.
CREATE TABLE dbo.[Transaction]
(
    TransactionID  BIGINT IDENTITY(1,1) NOT NULL,
    [Date]         DATE NOT NULL,
    [Time]         TIME(0) NOT NULL,
    Status         NVARCHAR(20) NOT NULL,
    Type           NVARCHAR(20) NOT NULL,
    Currency       CHAR(3) NOT NULL,
    Amount         DECIMAL(12,2) NOT NULL,
    CardNumber     NVARCHAR(19) NOT NULL,
    MerchantID     INT NOT NULL,

    CONSTRAINT PK_Transaction
        PRIMARY KEY (TransactionID),

    CONSTRAINT FK_Transaction_Card
        FOREIGN KEY (CardNumber)
        REFERENCES dbo.Card(CardNumber),

    CONSTRAINT FK_Transaction_Merchant
        FOREIGN KEY (MerchantID)
        REFERENCES dbo.Merchant(MerchantID)
);
GO