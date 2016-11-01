﻿SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ('dbo.v_KP4_Wagon',N'V') IS NOT NULL
  DROP VIEW dbo.v_KP4_Wagon;
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[v_KP4_Wagon]
AS
SELECT     TOP (100) PERCENT 
	dbo.JobResponse.ID, 
	dbo.WorkPerformance.ID				AS WorkPerformanceID, 
	dbo.WorkPerformance.Description		AS WeightSheetNumber, 
	dbo.WorkResponse.ID					AS WorkResponseID, 
	dbo.PackagingUnits.ID				AS PackagingUnitsID, 
	dbo.PackagingUnits.Description		AS WagonNumber, 
	dbo.WorkResponse.Description		AS WaybillNumber, 
	dbo.JobResponse.WorkType, 
	dbo.MaterialDefinition.ID			AS MaterialDefinitionID, 
	dbo.MaterialDefinition.Description	AS Group_Lom, 
	om1.ID				AS OpMaterialActualID, 
	om2.ID				AS OpMaterialActualID2, 
	om1.MaterialDefinitionID AS CSH, 
	case
		when dbo.JobResponse.WorkType = 'Taring'
		then dbo.OpPackagingActualProperty.Value
		when dbo.JobResponse.WorkType = 'Weighting'
		then (SELECT Value FROM   dbo.PackagingUnitsProperty WHERE	PackagingDefinitionPropertyID=2	AND PackagingUnitsID = dbo.PackagingUnits.ID)
	end									AS Tare, 
	brutto.Value			AS Brutto, 
	netto.Value	            AS Netto, 
	--dbo.JobResponsetData.Value			AS Brutto, 
	--dbo.MaterialActualProperty.Value	AS Netto, 
	dbo.OpPackagingActual.ID			AS OpPackagingActualID,
	dbo.JobResponse.StartTime			AS WeightingTime,
	cast(ROW_NUMBER() over (partition by dbo.WorkPerformance.ID, dbo.WorkResponse.ID order by dbo.JobResponse.ID) as int)	AS WeightingIndex,
	cast(DENSE_RANK() over (partition by dbo.WorkPerformance.ID order by dbo.WorkResponse.ID) as int)						AS WagonIndex,
	oe1.Description as sender,
	oe2.Description as reciever
FROM
	dbo.JobResponse INNER JOIN
	dbo.WorkResponse ON dbo.JobResponse.WorkResponse = dbo.WorkResponse.ID INNER JOIN
	dbo.WorkPerformance ON dbo.WorkResponse.WorkPerfomence = dbo.WorkPerformance.ID LEFT OUTER JOIN
	dbo.OpPackagingActual ON dbo.JobResponse.ID = dbo.OpPackagingActual.JobResponseID LEFT OUTER JOIN
	dbo.OpPackagingActualProperty ON dbo.OpPackagingActual.ID = dbo.OpPackagingActualProperty.OpPackagingActualID LEFT OUTER JOIN
	dbo.PackagingUnits ON dbo.OpPackagingActual.PackagingUnitsID = dbo.PackagingUnits.ID LEFT OUTER JOIN
	dbo.OpEquipmentActual oe1 ON dbo.JobResponse.ID = oe1.JobResponseID  AND oe1.EquipmentClassID=15 LEFT OUTER JOIN
	dbo.OpEquipmentActual oe2 ON dbo.JobResponse.ID = oe2.JobResponseID  AND oe2.EquipmentClassID=16 LEFT OUTER JOIN
	dbo.OpMaterialActual om1 ON dbo.JobResponse.ID = om1.JobResponseID  AND om1.MaterialClassID=10 LEFT OUTER JOIN
	dbo.OpMaterialActual om2 ON dbo.JobResponse.ID = om2.JobResponseID  AND om2.MaterialClassID=12 LEFT OUTER JOIN
	dbo.MaterialDefinition ON om1.MaterialDefinitionID = dbo.MaterialDefinition.ID LEFT OUTER JOIN
	dbo.MaterialActualProperty  brutto ON om1.ID = brutto.OpMaterialActual  LEFT OUTER JOIN
	dbo.MaterialActualProperty  netto  ON om2.ID = netto.OpMaterialActual  


GO