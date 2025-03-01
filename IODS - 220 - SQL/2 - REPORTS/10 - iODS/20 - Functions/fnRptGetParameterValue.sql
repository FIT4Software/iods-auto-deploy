USE [Auto_opsDataStore]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------------------------
-- Prototype definition
----------------------------------------------------------------------------------------------------------------------
DECLARE @SP_Name	NVARCHAR(200),
		@Inputs		INT,
		@Version	NVARCHAR(20),
		@AppId		INT

SELECT
		@SP_Name	= 'fnRptGetParameterValue',
		@Inputs		= 3, 
		@Version	= '1.0'  

--=====================================================================================================================
--	Update table AppVersions
--=====================================================================================================================

IF (SELECT COUNT(*) 
		FROM dbo.AppVersions 
		WHERE App_Name like @SP_Name) > 0
BEGIN
	UPDATE dbo.AppVersions 
		SET app_version = @Version,
			Modified_On = GETDATE() 
		WHERE App_Name like @SP_Name
END
ELSE
BEGIN
	INSERT INTO dbo.AppVersions (
		App_Name,
		App_version,
		Modified_On )
	VALUES (	
		@SP_Name,
		@Version,
		GETDATE())
END
--===================================================================================================================== 


----------------------------------------------------------------------------------------------------------------------
-- DROP StoredProcedure
----------------------------------------------------------------------------------------------------------------------
IF EXISTS ( SELECT *
			FROM	Information_schema.Routines
			WHERE	Specific_schema = 'dbo'
				AND	Specific_Name = @SP_Name
				AND	Routine_Type = 'FUNCTION' )
				
DROP FUNCTION [dbo].[fnRptGetParameterValue]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- ====================================================================================================================
-- --------------------------------------------------------------------------------------------------------------------
-- Function: [fnRptGetParameterValue]
-- --------------------------------------------------------------------------------------------------------------------
-- Author				: Martin Casalis - Arido Software
-- Date created			: 2018-07-05
-- Version 				: 1.0
-- Caller				: Report
-- Description			: This function get report parameters values for a report
-- --------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- --------------------------------------------------------------------------------------------------------------------
-- 1.0		2018-07-05		Martin Casalis     		Initial Release
-- --------------------------------------------------------------------------------------------------------------------
-- ====================================================================================================================

CREATE FUNCTION [dbo].[fnRptGetParameterValue] (
--DECLARE
		@ReportName		NVARCHAR(100)	,
		@Parameter		NVARCHAR(100)	
		)
		RETURNS NVARCHAR(MAX)		

--WITH ENCRYPTION
AS 
BEGIN
		
	DECLARE		@Output			NVARCHAR(MAX) = '',
				@initialPos		INT	,
				@endPos			INT	

	-- Testing Statements
	--SELECT	@Parameter  = '@TimeOption',	--'@RptNegMin',	--
	--		@ReportName = 'PPM/VAS Report'


	IF (SELECT CHARINDEX(@Parameter,GlobalParameters) 
		FROM [dbo].[ReportTypes] (NOLOCK)	
		WHERE ReportName = @ReportName) > 0
	BEGIN
			SELECT @initialPos = CHARINDEX('"',GlobalParameters,CHARINDEX(@Parameter,GlobalParameters)) + 3
			FROM [dbo].[ReportTypes] (NOLOCK)
			WHERE ReportName = @ReportName
	
			SELECT @endPos = CHARINDEX('"',GlobalParameters,@initialPos + 1)
			FROM [dbo].[ReportTypes] (NOLOCK)
			WHERE ReportName = @ReportName
					
			IF @endPos - @initialPos > 0
			BEGIN
				SELECT @Output = SUBSTRING(GlobalParameters,@initialPos,@endPos - @initialPos)
				FROM [dbo].[ReportTypes] (NOLOCK)
				WHERE ReportName = @ReportName
			END
	END

	IF @Output LIKE '%"%' OR @Output = '' SET @Output = NULL

	--SELECT @Output

	RETURN @Output
END

GO
GRANT EXECUTE ON [Auto_opsDataStore].[dbo].[fnRptGetParameterValue] TO RptUser 
GO