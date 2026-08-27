-- Validate the Bank Card ETL result.

USE BankCardDWH;
GO


-- Compare source and DWH dimension counts.

SELECT
    (SELECT COUNT(*) FROM BankCardDB.dbo.Customer) AS [SourceCustomers],
    (SELECT COUNT(*) FROM dwh.Customer) AS [DWHCustomers],

    (SELECT COUNT(*) FROM BankCardDB.dbo.Card) AS [SourceCards],
    (SELECT COUNT(*) FROM dwh.Card) AS [DWHCards],

    (SELECT COUNT(*) FROM BankCardDB.dbo.Merchant) AS [SourceMerchants],
    (SELECT COUNT(*) FROM dwh.Merchant) AS [DWHMerchants];
GO


-- Compare expected and loaded Time rows.

SELECT
    DATEDIFF
    (
        DAY,
        (SELECT MIN([Date]) FROM BankCardDB.dbo.[Transaction]),
        CASE
            WHEN (SELECT MAX([Date]) FROM BankCardDB.dbo.[Transaction])
                 > CAST(GETDATE() AS DATE)
                THEN CAST(GETDATE() AS DATE)
            ELSE
                (SELECT MAX([Date]) FROM BankCardDB.dbo.[Transaction])
        END
    ) + 1 AS [ExpectedTimeRows],

    (SELECT COUNT(*) FROM dwh.[Time]) AS [DWHTimeRows];
GO


-- Compare expected and loaded Transaction facts.

SELECT
    (
        SELECT COUNT(*)
        FROM BankCardDB.dbo.[Transaction]
        WHERE [Date] <= CAST(GETDATE() AS DATE)
          AND UPPER(LTRIM(RTRIM([Type]))) = 'PURCHASE'
          AND UPPER(LTRIM(RTRIM([Status])))
              IN ('COMPLETE', 'COMPLETED')
    ) AS [ExpectedTransactions],

    (SELECT COUNT(*) FROM dwh.[Transaction]) AS [DWHTransactions];
GO


-- Check for duplicate Transaction IDs.

SELECT
    TransactionID,
    COUNT(*) AS [DuplicateCount]
FROM dwh.[Transaction]
GROUP BY TransactionID
HAVING COUNT(*) > 1;
GO


-- Check for invalid or missing Fact values.

SELECT COUNT(*) AS [InvalidFactRows]
FROM dwh.[Transaction]
WHERE TimeID IS NULL
   OR CardID IS NULL
   OR CustomerID IS NULL
   OR MerchantID IS NULL
   OR TransactionAmountEUR IS NULL;
GO


-- Check Fact foreign-key relationships.

SELECT COUNT(*) AS [InvalidForeignKeys]
FROM dwh.[Transaction] AS f
LEFT JOIN dwh.[Time] AS t
    ON f.TimeID = t.TimeID
LEFT JOIN dwh.Card AS c
    ON f.CardID = c.CardID
LEFT JOIN dwh.Customer AS cu
    ON f.CustomerID = cu.CustomerID
LEFT JOIN dwh.Merchant AS m
    ON f.MerchantID = m.MerchantID
WHERE t.TimeID IS NULL
   OR c.CardID IS NULL
   OR cu.CustomerID IS NULL
   OR m.MerchantID IS NULL;
GO


-- Check that no future transactions were loaded.

SELECT COUNT(*) AS [FutureFactRows]
FROM dwh.[Transaction] AS f
INNER JOIN dwh.[Time] AS t
    ON f.TimeID = t.TimeID
WHERE t.[Day] > CAST(GETDATE() AS DATE);
GO


-- Check current Customer SCD versions.

SELECT
    SourceCustomerID,
    COUNT(*) AS [CurrentVersionCount]
FROM dwh.Customer
WHERE ValidTo IS NULL
GROUP BY SourceCustomerID
HAVING COUNT(*) > 1;
GO


-- Check current Merchant SCD versions.

SELECT
    SourceMerchantID,
    COUNT(*) AS [CurrentVersionCount]
FROM dwh.Merchant
WHERE ValidTo IS NULL
GROUP BY SourceMerchantID
HAVING COUNT(*) > 1;
GO


-- Show a sample of the final Star Schema data.

SELECT TOP (10)
    f.TransactionID,
    t.[Day],
    cu.CustomerName,
    c.CardType,
    m.MerchantName,
    m.MerchantCategory,
    f.TransactionAmountEUR
FROM dwh.[Transaction] AS f
INNER JOIN dwh.[Time] AS t
    ON f.TimeID = t.TimeID
INNER JOIN dwh.Customer AS cu
    ON f.CustomerID = cu.CustomerID
INNER JOIN dwh.Card AS c
    ON f.CardID = c.CardID
INNER JOIN dwh.Merchant AS m
    ON f.MerchantID = m.MerchantID
ORDER BY f.TransactionID;
GO


-- Check the incremental-load control value.

USE STG_BankCard;
GO

SELECT
    FactTableName,
    Last_loading_Date
FROM dbo.control_table
WHERE FactTableName = 'Transaction';
GO