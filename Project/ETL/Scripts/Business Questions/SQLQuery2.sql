-- Analyze card spending by merchant region and category.

SELECT
    m.MerchantRegion,
    m.MerchantCategory,
    COUNT(*) AS TransactionCount,
    SUM(f.TransactionAmountEUR) AS TotalTransactionValueEUR
FROM BankCardDWH.dwh.[Transaction] AS f
INNER JOIN BankCardDWH.dwh.Merchant AS m
    ON f.MerchantID = m.MerchantID
GROUP BY
    m.MerchantRegion,
    m.MerchantCategory
ORDER BY TotalTransactionValueEUR DESC;