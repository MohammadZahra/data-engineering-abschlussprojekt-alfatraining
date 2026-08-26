-- Verify the cleaned Business Database.

USE BankCardDB;
GO


------------------------------------------------------------
-- Verify final row counts.
------------------------------------------------------------

SELECT 'Customer' AS TableName, 119 AS ExpectedCount,
       COUNT(*) AS ActualCount
FROM dbo.Customer

UNION ALL
SELECT 'Account', 139, COUNT(*)
FROM dbo.Account

UNION ALL
SELECT 'Card', 179, COUNT(*)
FROM dbo.Card

UNION ALL
SELECT 'Merchant', 40, COUNT(*)
FROM dbo.Merchant

UNION ALL
SELECT 'MerchantCategory', 12, COUNT(*)
FROM dbo.MerchantCategory

UNION ALL
SELECT 'AccountOwnership', 154, COUNT(*)
FROM dbo.AccountOwnership

UNION ALL
SELECT 'Transaction', 1987, COUNT(*)
FROM dbo.[Transaction];


------------------------------------------------------------
-- Check accounts without an owner.
------------------------------------------------------------

SELECT
    a.AccountNumber
FROM dbo.Account a
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.AccountOwnership ao
    WHERE ao.AccountNumber = a.AccountNumber
);


------------------------------------------------------------
-- Check cards whose holder does not own the linked account.
------------------------------------------------------------

SELECT
    c.CardNumber,
    c.CustomerID,
    c.AccountNumber
FROM dbo.Card c
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.AccountOwnership ao
    WHERE ao.CustomerID = c.CustomerID
      AND ao.AccountNumber = c.AccountNumber
);


------------------------------------------------------------
-- Verify standardized Account values.
------------------------------------------------------------

SELECT DISTINCT Type, Status, Currency
FROM dbo.Account
ORDER BY Type, Status, Currency;


------------------------------------------------------------
-- Verify standardized Card values.
------------------------------------------------------------

SELECT DISTINCT Type, Status
FROM dbo.Card
ORDER BY Type, Status;


------------------------------------------------------------
-- Verify standardized ownership roles.
------------------------------------------------------------

SELECT DISTINCT Role
FROM dbo.AccountOwnership
ORDER BY Role;


------------------------------------------------------------
-- Verify standardized Transaction values.
------------------------------------------------------------

SELECT DISTINCT Status, Type, Currency
FROM dbo.[Transaction]
ORDER BY Status, Type, Currency;


------------------------------------------------------------
-- Check unexpected categorical values.
------------------------------------------------------------

SELECT COUNT(*) AS InvalidTransactionValues
FROM dbo.[Transaction]
WHERE Status NOT IN ('Completed', 'Pending', 'Declined', 'Reversed')
   OR Type NOT IN ('Purchase', 'Refund', 'Reversal', 'Chargeback')
   OR Currency NOT IN ('EUR', 'USD', 'GBP', 'CHF');


------------------------------------------------------------
-- Check cleaned customer contact data.
------------------------------------------------------------

SELECT
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS MissingEmailCount,
    SUM(CASE WHEN Phone IS NULL THEN 1 ELSE 0 END) AS MissingPhoneCount
FROM dbo.Customer;