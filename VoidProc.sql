USE [CASDataWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Procedure: [dbo].[spVoid_ViewingActivity_Client]
Purpose:  Enable re-runs by removing any rows previously loaded for a given
          ImportedDocumentId from dbo.NetflixVA_Client.

Design:
- Simple and aligned with the retrieve/import targeting (ImportedDocumentId).
- No transactions or dynamic SQL needed; import will recalculate row counts.
*/
CREATE OR ALTER PROCEDURE [dbo].[spVoid_ViewingActivity_Client]
	@ImportedDocumentId	UniqueIdentifier
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM dbo.NetflixVA_Client
	WHERE ImportedDocumentId = @ImportedDocumentId;
END
GO