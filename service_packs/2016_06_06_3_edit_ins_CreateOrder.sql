﻿--------------------------------------------------------------
-- Процедура ins_CreateOrder
IF OBJECT_ID ('dbo.ins_Order',N'P') IS NOT NULL
   DROP PROCEDURE dbo.ins_Order;
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ins_Order] 
@COMM_ORDER		NVARCHAR(50),
@CONTRACT_NO	NVARCHAR(50),
@DIRECTION      NVARCHAR(50),
@TEMPLATE		INT,
@LENGTH			NVARCHAR(50),
@PROFILE		INT,
@ADDRESS		NVARCHAR(50) = NULL,
@BUNT_DIA		NVARCHAR(50) = NULL,
@CLASS			NVARCHAR(50) = NULL,
@MIN_ROD		NVARCHAR(50) = NULL,
@STEEL_CLASS	NVARCHAR(50) = NULL,
@PRODUCT		NVARCHAR(50) = NULL,
@STANDARD		NVARCHAR(50) = NULL,
@CHEM_ANALYSIS  NVARCHAR(50) = NULL
AS
BEGIN
   DECLARE @OperationsRequestID int,
           @OpSegmentRequirementID int,
           @OpMaterialRequirementID int;

   DECLARE @tblParams TABLE(ID    NVARCHAR(50),
                            Value NVARCHAR(50));

   IF @LENGTH IS NULL
	  RAISERROR ('LENGTH param required',16,1);
   ELSE IF @CONTRACT_NO IS NULL
	  RAISERROR ('CONTRACT_NO param required',16,1);
   ELSE IF @DIRECTION IS NULL
	  RAISERROR ('DIRECTION param required',16,1);
   ELSE IF @COMM_ORDER IS NULL
	  RAISERROR ('COMM_ORDER param required',16,1);
	 ELSE IF EXISTS (SELECT NULL FROM [dbo].[v_SegmentParameter_Order] WHERE [Value]=@COMM_ORDER)
	  RAISERROR (N'Заказ [%s] уже существует',16,1,@COMM_ORDER);
   ELSE IF @PROFILE IS NULL
	  RAISERROR ('PROFILE param required',16,1);
   ELSE IF @TEMPLATE IS NULL
	  RAISERROR ('TEMPLATE param required',16,1);
   ELSE IF NOT EXISTS (SELECT NULL FROM [dbo].[Files] WHERE [FileType]=N'Excel label' AND [ID]=@TEMPLATE)
      RAISERROR (N'Указанный Excel шаблон не существует в таблице Files',16,1);
   ELSE IF NOT EXISTS (SELECT NULL FROM [dbo].[MaterialDefinition] WHERE [ID]=@PROFILE)
      RAISERROR (N'Указанный профиль не существует в таблице MaterialDefinition',16,1);
   ELSE 
	BEGIN

	   SET @OperationsRequestID=NEXT VALUE FOR [dbo].[gen_OperationsRequest];
	   INSERT INTO [dbo].[OperationsRequest] ([ID]) VALUES (@OperationsRequestID);

	   SET @OpSegmentRequirementID=NEXT VALUE FOR [dbo].[gen_OpSegmentRequirement];
	   INSERT INTO [dbo].[OpSegmentRequirement] ([ID],[OperationsRequest]) VALUES (@OpSegmentRequirementID,@OperationsRequestID);

	   --SET @OpMaterialRequirementID=NEXT VALUE FOR [dbo].[gen_MaterialRequirement];
	   INSERT INTO [dbo].[OpMaterialRequirement] ([MaterialClassID],[MaterialDefinitionID],[SegmenRequirementID])
	   SELECT md.[MaterialClassID],md.[ID],@OpSegmentRequirementID
	   FROM [dbo].[MaterialDefinition] md 
	   WHERE md.[ID]=@PROFILE;

	   INSERT @tblParams
	   SELECT N'STANDARD',@STANDARD WHERE @STANDARD IS NOT NULL
	   UNION ALL
	   SELECT N'LENGTH',@LENGTH WHERE @LENGTH IS NOT NULL
	   UNION ALL
	   SELECT N'MIN_ROD',@MIN_ROD WHERE @MIN_ROD IS NOT NULL
	   UNION ALL
	   SELECT N'CONTRACT_NO',@CONTRACT_NO WHERE @CONTRACT_NO IS NOT NULL
	   UNION ALL
	   SELECT N'DIRECTION',@DIRECTION WHERE @DIRECTION IS NOT NULL
	   UNION ALL
	   SELECT N'PRODUCT',@PRODUCT WHERE @PRODUCT IS NOT NULL
	   UNION ALL
	   SELECT N'CLASS',@CLASS WHERE @CLASS IS NOT NULL
	   UNION ALL
	   SELECT N'STEEL_CLASS',@STEEL_CLASS WHERE @STEEL_CLASS IS NOT NULL
	   UNION ALL
	   SELECT N'CHEM_ANALYSIS',@CHEM_ANALYSIS WHERE @CHEM_ANALYSIS IS NOT NULL
	   UNION ALL
	   SELECT N'BUNT_DIA',@BUNT_DIA WHERE @BUNT_DIA IS NOT NULL
	   UNION ALL
	   SELECT N'ADDRESS',@ADDRESS WHERE @ADDRESS IS NOT NULL
	   UNION ALL
	   SELECT N'COMM_ORDER',@COMM_ORDER WHERE @COMM_ORDER IS NOT NULL
	   UNION ALL
	   SELECT N'TEMPLATE',CAST(@TEMPLATE AS NVARCHAR(50)) WHERE @TEMPLATE IS NOT NULL;

	   INSERT INTO [dbo].[SegmentParameter] ([Value],[OpSegmentRequirement],[PropertyType])
	   SELECT t.value,@OpSegmentRequirementID,pt.ID
	   FROM @tblParams t INNER JOIN [dbo].[PropertyTypes] pt ON (pt.value=t.ID);

   END;

END;
GO

