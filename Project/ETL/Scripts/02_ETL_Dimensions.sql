-- Create ETL procedures for all DWH dimensions.

USE STG_BankCard;
GO


-- Load the Customer dimension.

CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Customer
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BankCardDWH.dwh.Customer
    (
        SourceCustomerID,
        CustomerName,
        BirthDate,
        CustomerCity,
        CustomerRegion,
        CustomerCountry,
        ValidFrom,
        ValidTo
    )
    SELECT
        c.CustomerID,
        LTRIM(RTRIM(CONCAT(c.FirstName, ' ', c.LastName))),
        c.BirthDate,
        LTRIM(RTRIM(c.City)),
        LTRIM(RTRIM(c.Region)),
        LTRIM(RTRIM(c.Country)),
        CAST('19000101' AS DATETIME),
        NULL
    FROM BankCardDB.dbo.Customer AS c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM BankCardDWH.dwh.Customer AS d
        WHERE d.SourceCustomerID = c.CustomerID
    );
END;
GO


-- Load the Card dimension.

CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Card
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BankCardDWH.dwh.Card
    (
        SourceCardNumber,
        CardType
    )
    SELECT
        LTRIM(RTRIM(c.CardNumber)),
        LTRIM(RTRIM(c.[Type]))
    FROM BankCardDB.dbo.Card AS c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM BankCardDWH.dwh.Card AS d
        WHERE d.SourceCardNumber = LTRIM(RTRIM(c.CardNumber))
    );
END;
GO


-- Load the Merchant dimension.

CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Merchant
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BankCardDWH.dwh.Merchant
    (
        SourceMerchantID,
        MerchantName,
        MerchantCategory,
        MerchantStreet,
        MerchantPostalCode,
        MerchantCity,
        MerchantRegion,
        MerchantCountry,
        ValidFrom,
        ValidTo
    )
    SELECT
        m.MerchantID,
        LTRIM(RTRIM(m.Name)),
        LTRIM(RTRIM(mc.CategoryName)),
        LTRIM(RTRIM(m.Street)),
        LTRIM(RTRIM(m.PostalCode)),
        LTRIM(RTRIM(m.City)),
        LTRIM(RTRIM(m.Region)),
        LTRIM(RTRIM(m.Country)),
        CAST('19000101' AS DATETIME),
        NULL
    FROM BankCardDB.dbo.Merchant AS m
    INNER JOIN BankCardDB.dbo.MerchantCategory AS mc
        ON m.MerchantCategoryID = mc.MerchantCategoryID
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM BankCardDWH.dwh.Merchant AS d
        WHERE d.SourceMerchantID = m.MerchantID
    );
END;
GO


-- Load the Time dimension.

CREATE OR ALTER PROCEDURE dbo.usp_Load_Dim_Time
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MinDate DATE;
    DECLARE @MaxDate DATE;

    SELECT
        @MinDate = MIN([Date]),
        @MaxDate =
            CASE
                WHEN MAX([Date]) > CAST(GETDATE() AS DATE)
                    THEN CAST(GETDATE() AS DATE)
                ELSE MAX([Date])
            END
    FROM BankCardDB.dbo.[Transaction];

    IF @MinDate IS NULL OR @MaxDate IS NULL
        RETURN;

    ;WITH DateSeries AS
    (
        SELECT @MinDate AS CalendarDate

        UNION ALL

        SELECT DATEADD(DAY, 1, CalendarDate)
        FROM DateSeries
        WHERE CalendarDate < @MaxDate
    )
    INSERT INTO BankCardDWH.dwh.[Time]
    (
        TimeID,
        [Day],
        [Week],
        [Month],
        [Quarter],
        [Year]
    )
    SELECT
        CAST(CONVERT(CHAR(8), ds.CalendarDate, 112) AS INT),
        ds.CalendarDate,
        DATEPART(ISO_WEEK, ds.CalendarDate),
        MONTH(ds.CalendarDate),
        DATEPART(QUARTER, ds.CalendarDate),
        YEAR(ds.CalendarDate)
    FROM DateSeries AS ds
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM BankCardDWH.dwh.[Time] AS d
        WHERE d.[Day] = ds.CalendarDate
    )
    OPTION (MAXRECURSION 0);
END;
GO