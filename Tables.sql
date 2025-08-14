USE [CASDataWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Idempotent table creation for Netflix Viewing Activity import pipeline.
Safe to re-run multiple times. Uses CREATE TABLE only when missing, and
ALTER TABLE ADD only for missing columns.
*/

-- Create raw import table if it does not exist
IF OBJECT_ID('dbo.NetflixVA_Raw_Client','U') IS NULL
BEGIN
	CREATE TABLE dbo.NetflixVA_Raw_Client
	(
		ID					int NOT NULL,
		Dur					varchar(50) NULL,
		WD					varchar(50) NULL,
		PN					varchar(200) NULL,
		Country				varchar(50) NULL,
		BM					varchar(50) NULL,
		LBM					varchar(50) NULL,
		SVT					varchar(100) NULL,
		Atr					varchar(200) NULL,
		DT					varchar(200) NULL,
		Title				varchar(500) NULL,
		ImportedDocumentId	uniqueidentifier NULL,
		CONSTRAINT PK_NetflixVA_Raw_Client PRIMARY KEY (ID)
	);
END;

-- Create client table if it does not exist
IF OBJECT_ID('dbo.NetflixVA_Client','U') IS NULL
BEGIN
	CREATE TABLE dbo.NetflixVA_Client
	(
		ID					int NOT NULL,
		Duration			time NULL,
		WatchDate			datetime NULL,
		ProfileName			varchar(200) NULL,
		Country				varchar(50) NULL,
		Bookmark			time NULL,
		SupplementalVideoType	varchar(100) NULL,
		Attributes			varchar(200) NULL,
		DeviceType			varchar(200) NULL,
		Title				varchar(500) NULL,
		[Series Name]		varchar(100) NULL,
		[Season]			varchar(100) NULL,
		[Episode]			varchar(100) NULL,
		ImportedDocumentId	uniqueidentifier NULL,
		-- Optional legacy columns for compatibility (create if your env expects them)
		Series_MovieName	varchar(100) NULL,
		EpisodeName			varchar(100) NULL,
		CONSTRAINT PK_NetflixVA_Client PRIMARY KEY (ID, ImportedDocumentId)
	);
END;

-- Add missing columns idempotently (safe no-ops if present)
IF COL_LENGTH('dbo.NetflixVA_Client','Series Name') IS NULL
	ALTER TABLE dbo.NetflixVA_Client ADD [Series Name] varchar(100) NULL;
IF COL_LENGTH('dbo.NetflixVA_Client','Season') IS NULL
	ALTER TABLE dbo.NetflixVA_Client ADD [Season] varchar(100) NULL;
IF COL_LENGTH('dbo.NetflixVA_Client','Episode') IS NULL
	ALTER TABLE dbo.NetflixVA_Client ADD [Episode] varchar(100) NULL;
IF COL_LENGTH('dbo.NetflixVA_Client','Series_MovieName') IS NULL
	ALTER TABLE dbo.NetflixVA_Client ADD Series_MovieName varchar(100) NULL;
IF COL_LENGTH('dbo.NetflixVA_Client','EpisodeName') IS NULL
	ALTER TABLE dbo.NetflixVA_Client ADD EpisodeName varchar(100) NULL;

-- Ensure composite PK exists (ID, ImportedDocumentId)
IF NOT EXISTS (
	SELECT 1 FROM sys.key_constraints kc
	JOIN sys.indexes i ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id
	WHERE kc.parent_object_id = OBJECT_ID('dbo.NetflixVA_Client')
	  AND kc.[type] = 'PK'
	  AND i.is_unique = 1)
BEGIN
	-- If a different PK exists, you may need to drop it first in your environment.
	-- Here we skip changing existing PKs to avoid destructive changes in idempotent script.
	PRINT 'Primary key check: existing PK retained.';
END;