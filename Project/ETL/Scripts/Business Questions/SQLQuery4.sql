-- Analyze card type performance over time.

SELECT
    t.[Year],
    t.[Month],
    c.CardType,
    COUNT(*) AS TransactionCount,
    SUM(f.TransactionAmountEUR) AS TotalTransactionValueEUR
FROM BankCardDWH.dwh.[Transaction] AS f
INNER JOIN BankCardDWH.dwh.Card AS c
    ON f.CardID = c.CardID
INNER JOIN BankCardDWH.dwh.[Time] AS t
    ON f.TimeID = t.TimeID
GROUP BY
    t.[Year],
    t.[Month],
    c.CardType
ORDER BY
    t.[Year],
    t.[Month],
    TotalTransactionValueEUR DESC;