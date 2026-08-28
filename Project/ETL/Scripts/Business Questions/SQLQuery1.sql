-- Analyze transaction value and count by customer age group and merchant category.

WITH CustomerAge AS
(
    SELECT
        f.TransactionID,
        f.TransactionAmountEUR,
        m.MerchantCategory,
        DATEDIFF(YEAR, c.BirthDate, t.[Day])
        - CASE
            WHEN DATEADD(
                    YEAR,
                    DATEDIFF(YEAR, c.BirthDate, t.[Day]),
                    c.BirthDate
                 ) > t.[Day]
            THEN 1
            ELSE 0
          END AS Age
    FROM BankCardDWH.dwh.[Transaction] AS f
    INNER JOIN BankCardDWH.dwh.Customer AS c
        ON f.CustomerID = c.CustomerID
    INNER JOIN BankCardDWH.dwh.Merchant AS m
        ON f.MerchantID = m.MerchantID
    INNER JOIN BankCardDWH.dwh.[Time] AS t
        ON f.TimeID = t.TimeID
)
SELECT
    CASE
        WHEN Age < 25 THEN '<25'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN Age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS AgeGroup,
    MerchantCategory,
    COUNT(*) AS TransactionCount,
    SUM(TransactionAmountEUR) AS TotalTransactionValueEUR
FROM CustomerAge
GROUP BY
    CASE
        WHEN Age < 25 THEN '<25'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN Age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END,
    MerchantCategory
--ORDER BY TotalTransactionValueEUR DESC;
ORDER BY MerchantCategory DESC;
