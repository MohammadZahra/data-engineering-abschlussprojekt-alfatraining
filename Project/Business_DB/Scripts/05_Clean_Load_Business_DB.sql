-- Clean and load staging data into the Business Database.
USE BankCardDB;


GO
SET NOCOUNT ON;

SET XACT_ABORT ON;

-- Prevent accidental duplicate loading.
IF EXISTS (SELECT 1
           FROM   dbo.[Transaction])
   OR EXISTS (SELECT 1
              FROM   dbo.Card)
   OR EXISTS (SELECT 1
              FROM   dbo.AccountOwnership)
   OR EXISTS (SELECT 1
              FROM   dbo.Merchant)
   OR EXISTS (SELECT 1
              FROM   dbo.MerchantCategory)
   OR EXISTS (SELECT 1
              FROM   dbo.Account)
   OR EXISTS (SELECT 1
              FROM   dbo.Customer)
    BEGIN
        RAISERROR('Business Database tables are not empty.', 16, 1);
        RETURN;
    END;

BEGIN TRY
    BEGIN TRANSACTION;
    ------------------------------------------------------------
    -- Create temporary source-to-target ID mappings.
    ------------------------------------------------------------
    CREATE TABLE #MerchantCategoryMap (
        SourceMerchantCategoryID NVARCHAR (255) PRIMARY KEY,
        MerchantCategoryID       INT            NOT NULL
    );
    CREATE TABLE #CustomerMap (
        SourceCustomerID NVARCHAR (255) PRIMARY KEY,
        CustomerID       INT            NOT NULL
    );
    CREATE TABLE #MerchantMap (
        SourceMerchantID NVARCHAR (255) PRIMARY KEY,
        MerchantID       INT            NOT NULL
    ); ------------------------------------------------------------
    -- Load MerchantCategory.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT LTRIM(RTRIM(MerchantCategoryID)) AS SourceMerchantCategoryID,
                 CASE LTRIM(RTRIM(MerchantCategoryID)) WHEN 'MC01' THEN N'Groceries & Supermarkets' WHEN 'MC02' THEN N'Restaurants & Cafes' WHEN 'MC03' THEN N'Fuel & Automotive' WHEN 'MC04' THEN N'Travel & Transport' WHEN 'MC05' THEN N'Hotels & Lodging' WHEN 'MC06' THEN N'Retail & Fashion' WHEN 'MC07' THEN N'Electronics' WHEN 'MC08' THEN N'Health & Pharmacy' WHEN 'MC09' THEN N'Entertainment' WHEN 'MC10' THEN N'Utilities & Telecom' WHEN 'MC11' THEN N'Education' WHEN 'MC12' THEN N'Online Services' ELSE LTRIM(RTRIM(CategoryName)) END AS CategoryName,
                 NULLIF (LTRIM(RTRIM(Description)), '') AS Description,
                 ROW_NUMBER() OVER (PARTITION BY LTRIM(RTRIM(MerchantCategoryID)) ORDER BY MerchantCategoryID) AS rn
          FROM   stg.MerchantCategory)
    MERGE INTO dbo.MerchantCategory
     AS target
    USING (SELECT SourceMerchantCategoryID,
                  CategoryName,
                  Description
           FROM   Cleaned
           WHERE  rn = 1
                  AND SourceMerchantCategoryID IS NOT NULL
                  AND CategoryName IS NOT NULL) AS source ON 1 = 0
    WHEN NOT MATCHED THEN INSERT (CategoryName, Description) VALUES (source.CategoryName, source.Description)
    OUTPUT source.SourceMerchantCategoryID, inserted.MerchantCategoryID INTO #MerchantCategoryMap (SourceMerchantCategoryID, MerchantCategoryID);
    ------------------------------------------------------------
    -- Load Customer.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT LTRIM(RTRIM(CustomerID)) AS SourceCustomerID,
                 LTRIM(RTRIM(FirstName)) AS FirstName,
                 LTRIM(RTRIM(LastName)) AS LastName,
                 COALESCE (TRY_CONVERT (DATE, LTRIM(RTRIM(BirthDate)), 23), TRY_CONVERT (DATE, LTRIM(RTRIM(BirthDate)), 111), TRY_CONVERT (DATE, LTRIM(RTRIM(BirthDate)), 104), TRY_CONVERT (DATE, LTRIM(RTRIM(BirthDate)), 101)) AS BirthDate,
                 CASE WHEN Email IS NULL THEN NULL WHEN LTRIM(RTRIM(Email)) LIKE '%_@_%._%' THEN LTRIM(RTRIM(Email)) ELSE NULL END AS Email,
                 NULLIF (LTRIM(RTRIM(Phone)), '') AS Phone,
                 LTRIM(RTRIM(Street)) AS Street,
                 LTRIM(RTRIM(PostalCode)) AS PostalCode,
                 LTRIM(RTRIM(City)) AS City,
                 NULLIF (LTRIM(RTRIM(Region)), '') AS Region,
                 CASE LOWER(LTRIM(RTRIM(Country))) WHEN 'germany' THEN N'Germany' WHEN 'deutschland' THEN N'Germany' WHEN 'de' THEN N'Germany' WHEN 'austria' THEN N'Austria' WHEN 'at' THEN N'Austria' WHEN 'switzerland' THEN N'Switzerland' WHEN 'ch' THEN N'Switzerland' WHEN 'france' THEN N'France' WHEN 'fr' THEN N'France' WHEN 'belgium' THEN N'Belgium' WHEN 'be' THEN N'Belgium' WHEN 'netherlands' THEN N'Netherlands' WHEN 'nl' THEN N'Netherlands' WHEN 'united kingdom' THEN N'United Kingdom' WHEN 'uk' THEN N'United Kingdom' WHEN 'gb' THEN N'United Kingdom' ELSE LTRIM(RTRIM(Country)) END AS Country
          FROM   stg.Customer),
         Ranked
    AS   (SELECT *,
                 ROW_NUMBER() OVER (PARTITION BY SourceCustomerID ORDER BY CASE WHEN BirthDate IS NOT NULL THEN 0 ELSE 1 END, FirstName, LastName) AS rn
          FROM   Cleaned)
    MERGE INTO dbo.Customer
     AS target
    USING (SELECT SourceCustomerID,
                  FirstName,
                  LastName,
                  BirthDate,
                  Email,
                  Phone,
                  Street,
                  PostalCode,
                  City,
                  Region,
                  Country
           FROM   Ranked
           WHERE  rn = 1
                  AND SourceCustomerID IS NOT NULL
                  AND FirstName IS NOT NULL
                  AND LastName IS NOT NULL
                  AND BirthDate IS NOT NULL
                  AND Street IS NOT NULL
                  AND PostalCode IS NOT NULL
                  AND City IS NOT NULL
                  AND Country IS NOT NULL) AS source ON 1 = 0
    WHEN NOT MATCHED THEN INSERT (FirstName, LastName, BirthDate, Email, Phone, Street, PostalCode, City, Region, Country) VALUES (source.FirstName, source.LastName, source.BirthDate, source.Email, source.Phone, source.Street, source.PostalCode, source.City, source.Region, source.Country)
    OUTPUT source.SourceCustomerID, inserted.CustomerID INTO #CustomerMap (SourceCustomerID, CustomerID);
    ------------------------------------------------------------
    -- Load Account.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT LTRIM(RTRIM(AccountNumber)) AS AccountNumber,
                 CASE LOWER(LTRIM(RTRIM(Type))) WHEN 'current' THEN N'Current' WHEN 'savings' THEN N'Savings' WHEN 'credit' THEN N'Credit' WHEN 'business' THEN N'Business' ELSE NULL END AS Type,
                 CASE UPPER(LTRIM(RTRIM(Currency))) WHEN 'EUR' THEN 'EUR' WHEN 'EU' THEN 'EUR' WHEN 'USD' THEN 'USD' WHEN 'GBP' THEN 'GBP' WHEN 'CHF' THEN 'CHF' ELSE NULL END AS Currency,
                 CASE LOWER(LTRIM(RTRIM(Status))) WHEN 'active' THEN N'Active' WHEN 'closed' THEN N'Closed' WHEN 'dormant' THEN N'Dormant' ELSE NULL END AS Status,
                 COALESCE (TRY_CONVERT (DATE, LTRIM(RTRIM(OpeningDate)), 23), TRY_CONVERT (DATE, LTRIM(RTRIM(OpeningDate)), 111), TRY_CONVERT (DATE, LTRIM(RTRIM(OpeningDate)), 104), TRY_CONVERT (DATE, LTRIM(RTRIM(OpeningDate)), 101)) AS OpeningDate
          FROM   stg.Account)
    INSERT INTO dbo.Account (AccountNumber, Type, Currency, Status, OpeningDate)
    SELECT DISTINCT AccountNumber,
                    Type,
                    Currency,
                    Status,
                    OpeningDate
    FROM   Cleaned AS c
    WHERE  c.AccountNumber IS NOT NULL
           AND c.Type IS NOT NULL
           AND c.Currency IS NOT NULL
           AND c.Status IS NOT NULL
           AND c.OpeningDate IS NOT NULL
           AND EXISTS (SELECT 1
                       FROM   stg.AccountOwnership AS ao
                              INNER JOIN
                              #CustomerMap AS cm
                              ON cm.SourceCustomerID = LTRIM(RTRIM(ao.CustomerID))
                       WHERE  LTRIM(RTRIM(ao.AccountNumber)) = c.AccountNumber);
    ------------------------------------------------------------
    -- Load Merchant.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT LTRIM(RTRIM(m.MerchantID)) AS SourceMerchantID,
                 LTRIM(RTRIM(m.Name)) AS Name,
                 NULLIF (LTRIM(RTRIM(m.Street)), '') AS Street,
                 CASE WHEN NULLIF (LTRIM(RTRIM(m.PostalCode)), '') IS NULL THEN NULL WHEN LTRIM(RTRIM(m.PostalCode)) LIKE '%[^0-9A-Za-z -]%' THEN NULL ELSE LTRIM(RTRIM(m.PostalCode)) END AS PostalCode,
                 LTRIM(RTRIM(m.City)) AS City,
                 NULLIF (LTRIM(RTRIM(m.Region)), '') AS Region,
                 CASE LOWER(LTRIM(RTRIM(m.Country))) WHEN 'germany' THEN N'Germany' WHEN 'deutschland' THEN N'Germany' WHEN 'de' THEN N'Germany' WHEN 'austria' THEN N'Austria' WHEN 'at' THEN N'Austria' WHEN 'switzerland' THEN N'Switzerland' WHEN 'ch' THEN N'Switzerland' WHEN 'france' THEN N'France' WHEN 'fr' THEN N'France' WHEN 'belgium' THEN N'Belgium' WHEN 'be' THEN N'Belgium' WHEN 'netherlands' THEN N'Netherlands' WHEN 'nl' THEN N'Netherlands' WHEN 'united kingdom' THEN N'United Kingdom' WHEN 'uk' THEN N'United Kingdom' WHEN 'gb' THEN N'United Kingdom' ELSE LTRIM(RTRIM(m.Country)) END AS Country,
                 mc.MerchantCategoryID
          FROM   stg.Merchant AS m
                 INNER JOIN
                 #MerchantCategoryMap AS mc
                 ON mc.SourceMerchantCategoryID = LTRIM(RTRIM(m.MerchantCategoryID))),
         Ranked
    AS   (SELECT *,
                 ROW_NUMBER() OVER (PARTITION BY SourceMerchantID ORDER BY Name, City) AS rn
          FROM   Cleaned)
    MERGE INTO dbo.Merchant
     AS target
    USING (SELECT SourceMerchantID,
                  Name,
                  Street,
                  PostalCode,
                  City,
                  Region,
                  Country,
                  MerchantCategoryID
           FROM   Ranked
           WHERE  rn = 1
                  AND SourceMerchantID IS NOT NULL
                  AND Name IS NOT NULL
                  AND City IS NOT NULL
                  AND Country IS NOT NULL) AS source ON 1 = 0
    WHEN NOT MATCHED THEN INSERT (Name, Street, PostalCode, City, Region, Country, MerchantCategoryID) VALUES (source.Name, source.Street, source.PostalCode, source.City, source.Region, source.Country, source.MerchantCategoryID)
    OUTPUT source.SourceMerchantID, inserted.MerchantID INTO #MerchantMap (SourceMerchantID, MerchantID);
    ------------------------------------------------------------
    -- Load AccountOwnership.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT cm.CustomerID,
                 LTRIM(RTRIM(a.AccountNumber)) AS AccountNumber,
                 CASE LOWER(LTRIM(RTRIM(a.Role))) WHEN 'primary' THEN N'Primary' WHEN 'business owner' THEN N'Business Owner' WHEN 'joint' THEN N'Joint' ELSE NULL END AS Role
          FROM   stg.AccountOwnership AS a
                 INNER JOIN
                 #CustomerMap AS cm
                 ON cm.SourceCustomerID = LTRIM(RTRIM(a.CustomerID))
                 INNER JOIN
                 dbo.Account AS acc
                 ON acc.AccountNumber = LTRIM(RTRIM(a.AccountNumber)))
    INSERT INTO dbo.AccountOwnership (CustomerID, AccountNumber, Role)
    SELECT DISTINCT CustomerID,
                    AccountNumber,
                    Role
    FROM   Cleaned
    WHERE  Role IS NOT NULL;
    ------------------------------------------------------------
    -- Load Card.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT LTRIM(RTRIM(c.CardNumber)) AS CardNumber,
                 COALESCE (TRY_CONVERT (DATE, LTRIM(RTRIM(c.ExpiryDate)), 23), TRY_CONVERT (DATE, LTRIM(RTRIM(c.ExpiryDate)), 104), EOMONTH(TRY_CONVERT (DATE, '01/' + LTRIM(RTRIM(c.ExpiryDate)), 103))) AS ExpiryDate,
                 CASE LOWER(LTRIM(RTRIM(c.Type))) WHEN 'debit' THEN N'Debit' WHEN 'credit' THEN N'Credit' WHEN 'virtual' THEN N'Virtual' ELSE NULL END AS Type,
                 CASE LOWER(LTRIM(RTRIM(c.Status))) WHEN 'active' THEN N'Active' WHEN 'blocked' THEN N'Blocked' WHEN 'expired' THEN N'Expired' ELSE NULL END AS Status,
                 cm.CustomerID,
                 LTRIM(RTRIM(c.AccountNumber)) AS AccountNumber
          FROM   stg.Card AS c
                 INNER JOIN
                 #CustomerMap AS cm
                 ON cm.SourceCustomerID = LTRIM(RTRIM(c.CustomerID))
                 INNER JOIN
                 dbo.AccountOwnership AS ao
                 ON ao.CustomerID = cm.CustomerID
                    AND ao.AccountNumber = LTRIM(RTRIM(c.AccountNumber))),
         Ranked
    AS   (SELECT *,
                 ROW_NUMBER() OVER (PARTITION BY CardNumber ORDER BY CASE WHEN ExpiryDate IS NOT NULL THEN 0 ELSE 1 END, CardNumber) AS rn
          FROM   Cleaned)
    INSERT INTO dbo.Card (CardNumber, ExpiryDate, Type, Status, CustomerID, AccountNumber)
    SELECT CardNumber,
           ExpiryDate,
           Type,
           Status,
           CustomerID,
           AccountNumber
    FROM   Ranked
    WHERE  rn = 1
           AND CardNumber IS NOT NULL
           AND ExpiryDate IS NOT NULL
           AND Type IS NOT NULL
           AND Status IS NOT NULL;
    ------------------------------------------------------------
    -- Load Transaction.
    ------------------------------------------------------------
    WITH Cleaned
    AS   (SELECT LTRIM(RTRIM(t.TransactionID)) AS SourceTransactionID,
                 COALESCE (TRY_CONVERT (DATE, LTRIM(RTRIM(t.[Date])), 23), TRY_CONVERT (DATE, LTRIM(RTRIM(t.[Date])), 111), TRY_CONVERT (DATE, LTRIM(RTRIM(t.[Date])), 104), TRY_CONVERT (DATE, LTRIM(RTRIM(t.[Date])), 105), TRY_CONVERT (DATE, LTRIM(RTRIM(t.[Date])), 101)) AS [Date],
                 TRY_CONVERT (TIME (0), LTRIM(RTRIM(t.[Time]))) AS [Time],
                 CASE LOWER(LTRIM(RTRIM(t.Status))) WHEN 'completed' THEN N'Completed' WHEN 'complete' THEN N'Completed' WHEN 'pending' THEN N'Pending' WHEN 'declined' THEN N'Declined' WHEN 'decline' THEN N'Declined' WHEN 'reversed' THEN N'Reversed' ELSE NULL END AS Status,
                 CASE WHEN LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(t.Type)), ' ', ''), '-', ''), '_', '')) = 'purchase' THEN N'Purchase' WHEN LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(t.Type)), ' ', ''), '-', ''), '_', '')) = 'refund' THEN N'Refund' WHEN LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(t.Type)), ' ', ''), '-', ''), '_', '')) = 'reversal' THEN N'Reversal' WHEN LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(t.Type)), ' ', ''), '-', ''), '_', '')) = 'chargeback' THEN N'Chargeback' ELSE NULL END AS Type,
                 CASE UPPER(LTRIM(RTRIM(t.Currency))) WHEN 'EUR' THEN 'EUR' WHEN 'USD' THEN 'USD' WHEN 'GBP' THEN 'GBP' WHEN 'CHF' THEN 'CHF' ELSE NULL END AS Currency,
                 TRY_CONVERT (DECIMAL (12, 2), REPLACE(LTRIM(RTRIM(t.Amount)), ',', '.')) AS Amount,
                 LTRIM(RTRIM(t.CardNumber)) AS CardNumber,
                 mm.MerchantID
          FROM   stg.[Transaction] AS t
                 INNER JOIN
                 dbo.Card AS c
                 ON c.CardNumber = LTRIM(RTRIM(t.CardNumber))
                 INNER JOIN
                 #MerchantMap AS mm
                 ON mm.SourceMerchantID = LTRIM(RTRIM(t.MerchantID))),
         Ranked
    AS   (SELECT *,
                 ROW_NUMBER() OVER (PARTITION BY SourceTransactionID ORDER BY CASE WHEN [Date] IS NOT NULL
                                                                                        AND [Time] IS NOT NULL
                                                                                        AND Status IS NOT NULL
                                                                                        AND Type IS NOT NULL
                                                                                        AND Currency IS NOT NULL
                                                                                        AND Amount IS NOT NULL THEN 0 ELSE 1 END, [Date], [Time]) AS rn
          FROM   Cleaned)
    INSERT INTO dbo.[Transaction] ([Date], [Time], Status, Type, Currency, Amount, CardNumber, MerchantID)
    SELECT [Date],
           [Time],
           Status,
           Type,
           Currency,
           Amount,
           CardNumber,
           MerchantID
    FROM   Ranked
    WHERE  rn = 1
           AND SourceTransactionID IS NOT NULL
           AND [Date] IS NOT NULL
           AND [Time] IS NOT NULL
           AND Status IS NOT NULL
           AND Type IS NOT NULL
           AND Currency IS NOT NULL
           AND Amount IS NOT NULL
           AND CardNumber IS NOT NULL;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH

------------------------------------------------------------
-- Verify Business Database row counts.
------------------------------------------------------------
SELECT 'Customer' AS TableName,
       COUNT(*) AS RecordCount
FROM   dbo.Customer
UNION ALL
SELECT 'Account',
       COUNT(*)
FROM   dbo.Account
UNION ALL
SELECT 'Card',
       COUNT(*)
FROM   dbo.Card
UNION ALL
SELECT 'Merchant',
       COUNT(*)
FROM   dbo.Merchant
UNION ALL
SELECT 'MerchantCategory',
       COUNT(*)
FROM   dbo.MerchantCategory
UNION ALL
SELECT 'AccountOwnership',
       COUNT(*)
FROM   dbo.AccountOwnership
UNION ALL
SELECT 'Transaction',
       COUNT(*)
FROM   dbo.[Transaction];