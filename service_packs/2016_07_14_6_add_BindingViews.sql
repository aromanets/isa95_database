﻿SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.v_BindingDia', N'V') IS NOT NULL
    DROP VIEW dbo.[v_BindingDia];
GO

CREATE VIEW [dbo].[v_BindingDia]
AS
SELECT min(p.ID) ID,
       p.[Value]
FROM MaterialDefinitionProperty p
     INNER JOIN MaterialClassProperty mcp ON p.ClassPropertyID = mcp.ID
                                             AND mcp.[Value] = N'BINDING_DIA'
     INNER JOIN MaterialClass mc ON mc.ID = mcp.MaterialClassID
                                    AND mc.Code = N'BINDING'
 group by p.[Value];
GO

IF OBJECT_ID('dbo.v_BindingQty', N'V') IS NOT NULL
    DROP VIEW dbo.[v_BindingQty];
GO

CREATE VIEW [dbo].[v_BindingQty]
AS
SELECT min(p.ID) ID,
       p.[Value]
FROM MaterialDefinitionProperty p
     INNER JOIN MaterialClassProperty mcp ON p.ClassPropertyID = mcp.ID
                                             AND mcp.[Value] = N'BINDING_QTY'
     INNER JOIN MaterialClass mc ON mc.ID = mcp.MaterialClassID
                                    AND mc.Code = N'BINDING'
							 group by p.[Value];
GO