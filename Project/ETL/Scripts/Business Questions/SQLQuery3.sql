-- Analyze transaction development over time.

SELECT
    t.[Year],
    t.[Quarter],
    t.[Month],
    COUNT(*) AS TransactionCount,
    SUM(f.TransactionAmountEUR) AS TotalTransactionValueEUR
FROM BankCardDWH.dwh.[Transaction] AS f
INNER JOIN BankCardDWH.dwh.[Time] AS t
    ON f.TimeID = t.TimeID
GROUP BY
    t.[Year],
    t.[Quarter],
    t.[Month]
ORDER BY
    t.[Year],
    t.[Quarter],
    t.[Month];