USE [CASDataWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Procedure: [dbo].[spVoid_ViewingActivity_Client]
Purpose:  Allow safe re-runs of the viewing activity import by deleting prior rows
          for a given ImportedDocumentId from dbo.NetflixVA_Client, and resetting
          the ImportedDocument.RowsInserted to 0 (in the specified metadata DB).

Why dynamic SQL here:
- The metadata database name is variable (@CasinoInsightDatabaseName), so we must
  build the UPDATE statement dynamically while keeping it parameterized.
- sp_executesql with parameters prevents injection and allows plan reuse.
*/
CREATE OR ALTER PROCEDURE [dbo].[spVoid_ViewingActivity_Client]
	@ImportedDocumentId		UniqueIdentifier,
	@Debug					Char(1) = 'N',
	@CasinoInsightDatabaseName	VarChar(100) = Null
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRAN;

		-- Remove prior client rows for this document to enable a clean re-run
		IF IsNull(@Debug, 'N') = 'N'
			DELETE C
			FROM dbo.NetflixVA_Client AS C WITH (ROWLOCK)
			WHERE C.ImportedDocumentId = @ImportedDocumentId;

		-- Reset the ImportedDocument row count (if metadata DB is provided)
		IF IsNull(@Debug, 'N') = 'N' AND @CasinoInsightDatabaseName IS NOT NULL
		BEGIN
			DECLARE @Sql nvarchar(max);
			SET @Sql = N'UPDATE ' + QUOTENAME(@CasinoInsightDatabaseName) + N'..ImportedDocument
				SET RowsInserted = 0
				WHERE ImportedDocument.Id = @ImportedDocumentId';

			EXEC sp_executesql @Sql, N'@ImportedDocumentId UniqueIdentifier', @ImportedDocumentId;
		END

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK TRAN;
		THROW;
	END CATCH
END
GO