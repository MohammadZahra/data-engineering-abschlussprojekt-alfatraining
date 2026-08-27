-- Create the incremental ETL procedure for the Transaction fact table.

USE STG_BankCard;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_Fact_Transaction
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LastLoadingDate DATETIME2(0);
    DECLARE @CurrentLoadingDate DATETIME2(0) = SYSDATETIME();

    SELECT
        @LastLoadingDate = Last_loading_Date
    FROM dbo.control_table
    WHERE FactTableName = 'Transaction';

    IF @LastLoadingDate IS NULL
        SET @LastLoadingDate = '19000101';

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO BankCardDWH.dwh.[Transaction]
        (
            TransactionID,
            TimeID,
            CardID,
            CustomerID,
            MerchantID,
            TransactionAmountEUR
        )
        SELECT
            t.TransactionID,

            dt.TimeID,

            dcard.CardID,

            dcustomer.CustomerID,

            dmerchant.MerchantID,

            CAST(
                ROUND(
                    CASE UPPER(LTRIM(RTRIM(t.Currency)))
                        WHEN 'EUR' THEN t.Amount
                        WHEN 'USD' THEN t.Amount * 0.857486
                        WHEN 'GBP' THEN t.Amount * 1.168907
                        WHEN 'CHF' THEN t.Amount * 1.068262
                        ELSE NULL
                    END,
                    2
                )
                AS DECIMAL(12,2)
            ) AS TransactionAmountEUR

        FROM BankCardDB.dbo.[Transaction] AS t

        INNER JOIN BankCardDB.dbo.Card AS sc
            ON t.CardNumber = sc.CardNumber

        INNER JOIN BankCardDWH.dwh.[Time] AS dt
            ON dt.TimeID =
               CAST(CONVERT(CHAR(8), t.[Date], 112) AS INT)

        INNER JOIN BankCardDWH.dwh.Card AS dcard
            ON dcard.SourceCardNumber =
               LTRIM(RTRIM(t.CardNumber))

        INNER JOIN BankCardDWH.dwh.Customer AS dcustomer
            ON dcustomer.SourceCustomerID = sc.CustomerID
            AND t.[Date] >= dcustomer.ValidFrom
            AND
            (
                dcustomer.ValidTo IS NULL
                OR t.[Date] < dcustomer.ValidTo
            )

        INNER JOIN BankCardDWH.dwh.Merchant AS dmerchant
            ON dmerchant.SourceMerchantID = t.MerchantID
            AND t.[Date] >= dmerchant.ValidFrom
            AND
            (
                dmerchant.ValidTo IS NULL
                OR t.[Date] < dmerchant.ValidTo
            )

        WHERE
            CAST(t.[Date] AS DATETIME2(0)) > @LastLoadingDate
            AND CAST(t.[Date] AS DATETIME2(0)) <= @CurrentLoadingDate
            AND UPPER(LTRIM(RTRIM(t.[Type]))) = 'PURCHASE'
            AND UPPER(LTRIM(RTRIM(t.[Status])))
                IN ('COMPLETE', 'COMPLETED')
            AND NOT EXISTS
            (
                SELECT 1
                FROM BankCardDWH.dwh.[Transaction] AS f
                WHERE f.TransactionID = t.TransactionID
            );

        UPDATE dbo.control_table
        SET Last_loading_Date = @CurrentLoadingDate
        WHERE FactTableName = 'Transaction';

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO