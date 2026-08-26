-- Explore and profile the raw staging data.

USE BankCardDB;
GO

SET NOCOUNT ON;


------------------------------------------------------------
-- Check row counts.
------------------------------------------------------------

SELECT 'Customer' AS TableName, COUNT(*) AS RecordCount
FROM stg.Customer

UNION ALL
SELECT 'Account', COUNT(*)
FROM stg.Account

UNION ALL
SELECT 'Card', COUNT(*)
FROM stg.Card

UNION ALL
SELECT 'Merchant', COUNT(*)
FROM stg.Merchant

UNION ALL
SELECT 'MerchantCategory', COUNT(*)
FROM stg.MerchantCategory

UNION ALL
SELECT 'AccountOwnership', COUNT(*)
FROM stg.AccountOwnership

UNION ALL
SELECT 'Transaction', COUNT(*)
FROM stg.[Transaction];


------------------------------------------------------------
-- Check duplicate source IDs.
------------------------------------------------------------

SELECT
    'Customer' AS EntityName,
    LTRIM(RTRIM(CustomerID)) AS SourceKey,
    COUNT(*) AS DuplicateCount
FROM stg.Customer
GROUP BY LTRIM(RTRIM(CustomerID))
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'Account',
    LTRIM(RTRIM(AccountNumber)),
    COUNT(*)
FROM stg.Account
GROUP BY LTRIM(RTRIM(AccountNumber))
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'Card',
    LTRIM(RTRIM(CardNumber)),
    COUNT(*)
FROM stg.Card
GROUP BY LTRIM(RTRIM(CardNumber))
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'Merchant',
    LTRIM(RTRIM(MerchantID)),
    COUNT(*)
FROM stg.Merchant
GROUP BY LTRIM(RTRIM(MerchantID))
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'MerchantCategory',
    LTRIM(RTRIM(MerchantCategoryID)),
    COUNT(*)
FROM stg.MerchantCategory
GROUP BY LTRIM(RTRIM(MerchantCategoryID))
HAVING COUNT(*) > 1

UNION ALL

SELECT
    'Transaction',
    LTRIM(RTRIM(TransactionID)),
    COUNT(*)
FROM stg.[Transaction]
GROUP BY LTRIM(RTRIM(TransactionID))
HAVING COUNT(*) > 1;


------------------------------------------------------------
-- Check duplicate ownership relationships.
------------------------------------------------------------

SELECT
    LTRIM(RTRIM(CustomerID)) AS CustomerID,
    LTRIM(RTRIM(AccountNumber)) AS AccountNumber,
    COUNT(*) AS DuplicateCount
FROM stg.AccountOwnership
GROUP BY
    LTRIM(RTRIM(CustomerID)),
    LTRIM(RTRIM(AccountNumber))
HAVING COUNT(*) > 1;


------------------------------------------------------------
-- Check missing required values.
------------------------------------------------------------

SELECT
    'Customer' AS EntityName,
    COUNT(*) AS RowsWithMissingRequiredValues
FROM stg.Customer
WHERE NULLIF(LTRIM(RTRIM(CustomerID)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(FirstName)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(LastName)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(BirthDate)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Street)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(PostalCode)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(City)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Country)), '') IS NULL

UNION ALL

SELECT
    'Account',
    COUNT(*)
FROM stg.Account
WHERE NULLIF(LTRIM(RTRIM(AccountNumber)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Type)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Currency)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Status)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(OpeningDate)), '') IS NULL

UNION ALL

SELECT
    'Card',
    COUNT(*)
FROM stg.Card
WHERE NULLIF(LTRIM(RTRIM(CardNumber)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(ExpiryDate)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Type)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Status)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(CustomerID)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(AccountNumber)), '') IS NULL

UNION ALL

SELECT
    'Transaction',
    COUNT(*)
FROM stg.[Transaction]
WHERE NULLIF(LTRIM(RTRIM(TransactionID)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM([Date])), '') IS NULL
   OR NULLIF(LTRIM(RTRIM([Time])), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Status)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Type)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Currency)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(Amount)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(CardNumber)), '') IS NULL
   OR NULLIF(LTRIM(RTRIM(MerchantID)), '') IS NULL;


------------------------------------------------------------
-- Check optional customer contact values.
------------------------------------------------------------

SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Email)), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingEmailCount,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Phone)), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingPhoneCount

FROM stg.Customer;


------------------------------------------------------------
-- Inspect categorical value variations.
------------------------------------------------------------

SELECT
    'Account.Type' AS FieldName,
    CONCAT(N'[', Type, N']') AS RawValue,
    COUNT(*) AS RecordCount
FROM stg.Account
GROUP BY Type

UNION ALL

SELECT
    'Account.Status',
    CONCAT(N'[', Status, N']'),
    COUNT(*)
FROM stg.Account
GROUP BY Status

UNION ALL

SELECT
    'Account.Currency',
    CONCAT(N'[', Currency, N']'),
    COUNT(*)
FROM stg.Account
GROUP BY Currency

UNION ALL

SELECT
    'AccountOwnership.Role',
    CONCAT(N'[', Role, N']'),
    COUNT(*)
FROM stg.AccountOwnership
GROUP BY Role

UNION ALL

SELECT
    'Card.Type',
    CONCAT(N'[', Type, N']'),
    COUNT(*)
FROM stg.Card
GROUP BY Type

UNION ALL

SELECT
    'Card.Status',
    CONCAT(N'[', Status, N']'),
    COUNT(*)
FROM stg.Card
GROUP BY Status

UNION ALL

SELECT
    'Transaction.Status',
    CONCAT(N'[', Status, N']'),
    COUNT(*)
FROM stg.[Transaction]
GROUP BY Status

UNION ALL

SELECT
    'Transaction.Type',
    CONCAT(N'[', Type, N']'),
    COUNT(*)
FROM stg.[Transaction]
GROUP BY Type

UNION ALL

SELECT
    'Transaction.Currency',
    CONCAT(N'[', Currency, N']'),
    COUNT(*)
FROM stg.[Transaction]
GROUP BY Currency

ORDER BY FieldName, RawValue;


------------------------------------------------------------
-- Check customer dates that cannot be converted.
------------------------------------------------------------

SELECT
    CustomerID,
    BirthDate
FROM stg.Customer
WHERE BirthDate IS NOT NULL
  AND COALESCE
      (
          TRY_CONVERT(DATE, LTRIM(RTRIM(BirthDate)), 23),
          TRY_CONVERT(DATE, LTRIM(RTRIM(BirthDate)), 111),
          TRY_CONVERT(DATE, LTRIM(RTRIM(BirthDate)), 104),
          TRY_CONVERT(DATE, LTRIM(RTRIM(BirthDate)), 101)
      ) IS NULL;


------------------------------------------------------------
-- Check account dates that cannot be converted.
------------------------------------------------------------

SELECT
    AccountNumber,
    OpeningDate
FROM stg.Account
WHERE OpeningDate IS NOT NULL
  AND COALESCE
      (
          TRY_CONVERT(DATE, LTRIM(RTRIM(OpeningDate)), 23),
          TRY_CONVERT(DATE, LTRIM(RTRIM(OpeningDate)), 104),
          TRY_CONVERT(DATE, LTRIM(RTRIM(OpeningDate)), 101)
      ) IS NULL;


------------------------------------------------------------
-- Check card dates that cannot be converted.
------------------------------------------------------------

SELECT
    CardNumber,
    ExpiryDate
FROM stg.Card
WHERE ExpiryDate IS NOT NULL
  AND COALESCE
      (
          TRY_CONVERT(DATE, LTRIM(RTRIM(ExpiryDate)), 23),
          TRY_CONVERT(DATE, LTRIM(RTRIM(ExpiryDate)), 104),
          EOMONTH
          (
              TRY_CONVERT
              (
                  DATE,
                  '01/' + LTRIM(RTRIM(ExpiryDate)),
                  103
              )
          )
      ) IS NULL;


------------------------------------------------------------
-- Check transaction dates that cannot be converted.
------------------------------------------------------------

SELECT
    TransactionID,
    [Date]
FROM stg.[Transaction]
WHERE [Date] IS NOT NULL
  AND COALESCE
      (
          TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 23),
          TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 111),
          TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 104),
          TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 105),
          TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 101)
      ) IS NULL;


------------------------------------------------------------
-- Check transaction times that cannot be converted.
------------------------------------------------------------

SELECT
    TransactionID,
    [Time]
FROM stg.[Transaction]
WHERE [Time] IS NOT NULL
  AND TRY_CONVERT
      (
          TIME(0),
          LTRIM(RTRIM([Time]))
      ) IS NULL;


------------------------------------------------------------
-- Check transaction amounts that cannot be converted.
------------------------------------------------------------

SELECT
    TransactionID,
    Amount
FROM stg.[Transaction]
WHERE Amount IS NOT NULL
  AND TRY_CONVERT
      (
          DECIMAL(12,2),
          REPLACE(LTRIM(RTRIM(Amount)), ',', '.')
      ) IS NULL;


------------------------------------------------------------
-- Check malformed customer email values.
------------------------------------------------------------

SELECT
    CustomerID,
    Email
FROM stg.Customer
WHERE Email IS NOT NULL
  AND LTRIM(RTRIM(Email)) NOT LIKE '%_@_%._%';


------------------------------------------------------------
-- Check suspicious merchant postal codes.
------------------------------------------------------------

SELECT
    MerchantID,
    PostalCode
FROM stg.Merchant
WHERE PostalCode IS NOT NULL
  AND LTRIM(RTRIM(PostalCode)) LIKE '%[^0-9A-Za-z -]%';


------------------------------------------------------------
-- Check missing source relationships.
------------------------------------------------------------

SELECT
    'AccountOwnership -> Customer' AS RelationshipName,
    COUNT(*) AS InvalidReferenceCount
FROM stg.AccountOwnership ao
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Customer c
    WHERE LTRIM(RTRIM(c.CustomerID))
        = LTRIM(RTRIM(ao.CustomerID))
)

UNION ALL

SELECT
    'AccountOwnership -> Account',
    COUNT(*)
FROM stg.AccountOwnership ao
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Account a
    WHERE LTRIM(RTRIM(a.AccountNumber))
        = LTRIM(RTRIM(ao.AccountNumber))
)

UNION ALL

SELECT
    'Card -> Customer',
    COUNT(*)
FROM stg.Card ca
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Customer c
    WHERE LTRIM(RTRIM(c.CustomerID))
        = LTRIM(RTRIM(ca.CustomerID))
)

UNION ALL

SELECT
    'Card -> Account',
    COUNT(*)
FROM stg.Card ca
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Account a
    WHERE LTRIM(RTRIM(a.AccountNumber))
        = LTRIM(RTRIM(ca.AccountNumber))
)

UNION ALL

SELECT
    'Merchant -> MerchantCategory',
    COUNT(*)
FROM stg.Merchant m
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.MerchantCategory mc
    WHERE LTRIM(RTRIM(mc.MerchantCategoryID))
        = LTRIM(RTRIM(m.MerchantCategoryID))
)

UNION ALL

SELECT
    'Transaction -> Card',
    COUNT(*)
FROM stg.[Transaction] t
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Card ca
    WHERE LTRIM(RTRIM(ca.CardNumber))
        = LTRIM(RTRIM(t.CardNumber))
)

UNION ALL

SELECT
    'Transaction -> Merchant',
    COUNT(*)
FROM stg.[Transaction] t
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.Merchant m
    WHERE LTRIM(RTRIM(m.MerchantID))
        = LTRIM(RTRIM(t.MerchantID))
);


------------------------------------------------------------
-- Check whether each cardholder owns the linked account.
------------------------------------------------------------

SELECT
    CardNumber,
    CustomerID,
    AccountNumber
FROM stg.Card ca
WHERE NOT EXISTS
(
    SELECT 1
    FROM stg.AccountOwnership ao
    WHERE LTRIM(RTRIM(ao.CustomerID))
        = LTRIM(RTRIM(ca.CustomerID))
      AND LTRIM(RTRIM(ao.AccountNumber))
        = LTRIM(RTRIM(ca.AccountNumber))
);


------------------------------------------------------
------------------------------------------------------

-- Check records depending on the invalid customer.
SELECT
    ca.CardNumber,
    ca.CustomerID,
    ca.AccountNumber
FROM stg.Card ca
WHERE LTRIM(RTRIM(ca.CustomerID)) = 'CUST0113';


-- Check transactions depending on rejected cards.
SELECT
    t.CardNumber,
    COUNT(*) AS TransactionCount
FROM stg.[Transaction] t
WHERE LTRIM(RTRIM(t.CardNumber)) = '9900000000000159'
   OR LTRIM(RTRIM(t.CardNumber)) IN
   (
       SELECT LTRIM(RTRIM(ca.CardNumber))
       FROM stg.Card ca
       WHERE LTRIM(RTRIM(ca.CustomerID)) = 'CUST0113'
   )
GROUP BY t.CardNumber;

--------------------
--------------------

-- Check accounts affected by the invalid customer.

SELECT
    ao.AccountNumber,
    COUNT(*) AS OwnerCount
FROM stg.AccountOwnership ao
WHERE LTRIM(RTRIM(ao.AccountNumber)) IN
(
    SELECT LTRIM(RTRIM(AccountNumber))
    FROM stg.AccountOwnership
    WHERE LTRIM(RTRIM(CustomerID)) = 'CUST0113'
)
GROUP BY ao.AccountNumber;

--------------------
--------------------

-- Calculate the expected number of valid transactions.

;WITH ValidTransactions AS
(
    SELECT
        LTRIM(RTRIM(TransactionID)) AS TransactionID,

        ROW_NUMBER() OVER
        (
            PARTITION BY LTRIM(RTRIM(TransactionID))
            ORDER BY TransactionID
        ) AS rn

    FROM stg.[Transaction]

    WHERE LTRIM(RTRIM(CardNumber)) <> '9900000000000159'

      AND COALESCE
          (
              TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 23),
              TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 111),
              TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 104),
              TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 105),
              TRY_CONVERT(DATE, LTRIM(RTRIM([Date])), 101)
          ) IS NOT NULL

      AND TRY_CONVERT
          (
              TIME(0),
              LTRIM(RTRIM([Time]))
          ) IS NOT NULL

      AND TRY_CONVERT
          (
              DECIMAL(12,2),
              REPLACE(LTRIM(RTRIM(Amount)), ',', '.')
          ) IS NOT NULL

      AND UPPER(LTRIM(RTRIM(Currency)))
          IN ('EUR', 'USD', 'GBP', 'CHF')
)

SELECT COUNT(*) AS ExpectedTransactionCount
FROM ValidTransactions
WHERE rn = 1;