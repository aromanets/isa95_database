﻿SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

DECLARE @EquipmentClassID int;

SELECT @EquipmentClassID = ID
FROM dbo.EquipmentClass
WHERE Code = N'SCALES';

IF NOT EXISTS
(
	SELECT NULL
	FROM dbo.EquipmentClassProperty
	WHERE [Value] = N'TAKE_WEIGHT_LOCKED'
)
BEGIN
	INSERT INTO dbo.EquipmentClassProperty( Description, [Value], EquipmentClassID )
	VALUES( N'Кнопка Взять Вес заблокированна', N'TAKE_WEIGHT_LOCKED', @EquipmentClassID );
END;

INSERT INTO dbo.EquipmentProperty( [Value], EquipmentID, ClassPropertyID )
	   SELECT N'0', ID, dbo.get_EquipmentClassPropertyByValue( N'TAKE_WEIGHT_LOCKED' )
	   FROM Equipment
	   WHERE EquipmentClassID = @EquipmentClassID AND 
			 ID NOT IN
	   (
		   SELECT EquipmentID
		   FROM EquipmentProperty
		   WHERE ClassPropertyID = dbo.get_EquipmentClassPropertyByValue( N'TAKE_WEIGHT_LOCKED' )
	   );

GO

--------------------------------------------------------------
-- Процедура ins_JobOrderOPCCommandTakeWeight
IF OBJECT_ID ('dbo.ins_JobOrderOPCCommandTakeWeight',N'P') IS NOT NULL
   DROP PROCEDURE dbo.ins_JobOrderOPCCommandTakeWeight;
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ins_JobOrderOPCCommandTakeWeight]
@EquipmentID     INT
AS
BEGIN

DECLARE @JobOrderID    INT,
        @WorkRequestID INT,
	   @TakeWeightLocked [NVARCHAR](50);

SET @JobOrderID=dbo.get_EquipmentPropertyValue(@EquipmentID,N'JOB_ORDER_ID');

SELECT @WorkRequestID=jo.[WorkRequest]
FROM [dbo].[JobOrder] jo
WHERE jo.[ID]=@JobOrderID;

SET @TakeWeightLocked=dbo.get_EquipmentPropertyValue(@EquipmentID,N'TAKE_WEIGHT_LOCKED');

IF @TakeWeightLocked NOT IN (N'1')
    EXEC [dbo].[upd_EquipmentProperty] @EquipmentID = @EquipmentID,
								@EquipmentClassPropertyValue = N'TAKE_WEIGHT_LOCKED',
								@EquipmentPropertyValue = N'1';

EXEC [dbo].[ins_JobOrderOPCCommand] @WorkRequestID = @WorkRequestID,
                                    @EquipmentID   = @EquipmentID,
                                    @Tag           = N'CMD_TAKE_WEIGHT',
                                    @TagType       = N'Boolean',
                                    @TagValue      = N'true';

END;
GO

SET NUMERIC_ROUNDABORT OFF;
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON;
GO

IF OBJECT_ID ('dbo.v_ScalesDetailInfo',N'V') IS NOT NULL
   DROP VIEW dbo.[v_ScalesDetailInfo];
GO

CREATE VIEW [dbo].[v_ScalesDetailInfo]
AS
     WITH BarWeight
          AS (SELECT CAST(par.[Value] AS FLOAT) PropertyValue,
                     pr.[Value] PropertyType,
                     ep.EquipmentId
              FROM [PropertyTypes] pr,
                   [dbo].[Parameter] par,
                   dbo.[EquipmentProperty] ep
              WHERE pr.[Value] IN(N'BAR_WEIGHT', N'MIN_WEIGHT', N'MAX_WEIGHT', N'BAR_QUANTITY')
              AND pr.ID = par.PropertyType
              AND ep.[ClassPropertyID] = dbo.get_EquipmentClassPropertyByValue(N'JOB_ORDER_ID')
          AND ep.[Value] = par.JobOrder),
          Kep_Data
          AS (SELECT *
              FROM
              (
                  SELECT ROW_NUMBER() OVER(PARTITION BY kl.[NUMBER_POCKET] ORDER BY kl.[TIMESTAMP] DESC) RowNumber,
                         kl.[WEIGHT_CURRENT],
                         kl.[WEIGHT_STAB],
                         kl.[WEIGHT_ZERO],
                         kl.[COUNT_BAR],
                         kl.[REM_BAR],
                         kl.[AUTO_MANU],
                         kl.[POCKET_LOC],
                         kl.[PACK_SANDWICH],
                         kl.[NUMBER_POCKET]
                  FROM dbo.KEP_logger kl
                  WHERE kl.[TIMESTAMP] >= DATEADD(hour, -1, GETDATE())
              ) ww
              WHERE ww.RowNumber = 1)
          SELECT eq.ID AS ID,
                 eq.[Description] AS ScalesName,
                 dbo.get_RoundedWeightByEquipment(kd.WEIGHT_CURRENT, eq.ID) WEIGHT_CURRENT,
                 kd.WEIGHT_STAB,
                 kd.WEIGHT_ZERO,
                 kd.AUTO_MANU,
                 kd.POCKET_LOC,
                 kd.PACK_SANDWICH,
                 CAST(0 AS   BIT) AS ALARM,
                 CAST(FLOOR(dbo.get_RoundedWeightByEquipment(kd.WEIGHT_CURRENT, eq.ID) / bw.PropertyValue) AS   INT) RodsQuantity,
                 kd.REM_BAR RodsLeft,
                 ISNULL(CAST(bminW.PropertyValue AS INT), 0) MinWeight,
                 ISNULL(CAST(bmaxW.PropertyValue AS INT), 0) MaxWeight,
                 ISNULL(dbo.get_RoundedWeight(bmaxW.PropertyValue * 1.2, 'UP', 100), dbo.get_EquipmentPropertyValue(eq.ID, N'MAX_WEIGHT')) MaxPossibleWeight,
                 ISNULL(dbo.get_EquipmentPropertyValue(eq.ID, N'SCALES_TYPE'), N'POCKET') SCALES_TYPE,
				 dbo.get_EquipmentPropertyValue(eq.ID, N'PACK_RULE') PACK_RULE,
				 CAST(bQty.PropertyValue AS INT)		BAR_QUANTITY,
			 ISNULL(dbo.get_EquipmentPropertyValue(eq.ID, N'TAKE_WEIGHT_LOCKED'), '0') TAKE_WEIGHT_LOCKED
          FROM dbo.Equipment eq
               INNER JOIN dbo.EquipmentProperty eqp ON(eqp.EquipmentID = eq.ID)
               INNER JOIN dbo.EquipmentClassProperty ecp ON(ecp.ID = eqp.ClassPropertyID
                                                            AND ecp.value = N'SCALES_NO')
               LEFT OUTER JOIN Kep_Data kd ON(ISNUMERIC(eqp.value) = 1
                                              AND kd.[NUMBER_POCKET] = CAST(eqp.value AS INT))
               LEFT OUTER JOIN BarWeight bw ON bw.EquipmentId = eq.ID
                                               AND bw.PropertyType = N'BAR_WEIGHT'
               LEFT OUTER JOIN BarWeight bminW ON bminW.EquipmentId = eq.ID
                                                  AND bminW.PropertyType = N'MIN_WEIGHT'
               LEFT OUTER JOIN BarWeight bmaxW ON bmaxW.EquipmentId = eq.ID
                                                  AND bmaxW.PropertyType = N'MAX_WEIGHT'
			LEFT OUTER JOIN BarWeight bQty ON bQty.EquipmentId = eq.ID
                                                  AND bQty.PropertyType = N'BAR_QUANTITY';
GO