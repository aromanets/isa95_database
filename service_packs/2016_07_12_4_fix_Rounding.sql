﻿SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
--------------------------------------------------------------
-- Функция округляет вес
IF OBJECT_ID('dbo.get_RoundedWeight', N'FN') IS NOT NULL
    DROP FUNCTION dbo.get_RoundedWeight;
GO

CREATE FUNCTION dbo.get_RoundedWeight
(@WeightValue INT,
 @RoundRule   NVARCHAR(50),
 @RoundPrecision  INT
)
RETURNS INT
AS
     BEGIN
         IF @RoundRule IS NULL
             RETURN @WeightValue;
         IF @RoundPrecision IS NULL
             RETURN @WeightValue;
         IF @RoundRule = 'UP'
             BEGIN
                 IF @WeightValue % @RoundPrecision = 0
                     RETURN @WeightValue;
                 ELSE
                 RETURN @WeightValue + @RoundPrecision - @WeightValue % @RoundPrecision;
             END;
         IF @RoundRule = 'DOWN'
             RETURN @WeightValue - @WeightValue % @RoundPrecision;
         RETURN @WeightValue;
     END;
GO
