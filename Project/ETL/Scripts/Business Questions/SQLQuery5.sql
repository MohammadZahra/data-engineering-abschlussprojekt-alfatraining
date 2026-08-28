-- Show the strongest merchant category in each region in 2026.

WITH RegionCategory AS
(
    SELECT
        m.MerchantRegion,
        m.MerchantCategory,
        COUNT(*) AS TransactionCount,
        SUM(f.TransactionAmountEUR) AS TotalAmountEUR
    FROM BankCardDWH.dwh.[Transaction] AS f
    INNER JOIN BankCardDWH.dwh.Merchant AS m
        ON f.MerchantID = m.MerchantID
    INNER JOIN BankCardDWH.dwh.[Time] AS t
        ON f.TimeID = t.TimeID
    WHERE t.[Year] = 2026
    GROUP BY
        m.MerchantRegion,
        m.MerchantCategory
),
Ranked AS
(
    SELECT *,
        ROW_NUMBER() OVER
        (
            PARTITION BY MerchantRegion
            ORDER BY TotalAmountEUR DESC
        ) AS rn
    FROM RegionCategory
)
SELECT TOP (5)
    MerchantRegion,
    MerchantCategory,
    TransactionCount,
    CAST(TotalAmountEUR AS DECIMAL(12,2)) AS TotalAmountEUR
FROM Ranked
WHERE rn = 1
ORDER BY TotalAmountEUR DESC;