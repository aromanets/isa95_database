USE [KRR-PA-ISA95_PRODUCTION]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ('dbo.ins_OperationsAcceptence',N'P') IS NOT NULL
   DROP PROCEDURE dbo.ins_OperationsAcceptence;
GO



CREATE PROCEDURE [dbo].[ins_OperationsAcceptence]
	@F_number int,
	@Op_Type nvarchar(50)	
	
AS
BEGIN
		Declare @status nvarchar(50)
		SET @status = 
			CASE @Op_Type
				when N'Принято' then N'В ремонте'
				when N'Выдано' then N'В работе'
				when N'Брак' then N'Брак'
		END
if @Op_Type = N'Принято'
begin		

insert into WorkResponse (
				Description,
				WorkType,
				StartTime
				) 
					values (
							@Op_Type,
							@Op_Type, GETDATE()
							)
insert into JobResponse (
				Description,
				WorkType,
				StartTime,
				WorkResponse
				)
					values (
							@Op_Type,
							@Op_Type, GETDATE(),
							(select max(ID) from WorkResponse)
							)
insert into OpMaterialActual(MaterialDefinitionID, MaterialLotID, JobResponseID)  	
		values ( 
			(select MaterialDefinitionID from MaterialLot where ID = @F_number), @F_number,
			(select max(ID) from JobResponse))
	insert into MaterialActualProperty (Description, Value, OpMaterialActual) 
		values('Update Status', @status,
		(select max(ID) from OpMaterialActual))

end

else

if 	@F_number = (select MaterialLotID from [dbo].[OpMaterialActual] 
		where  MaterialLotID =@F_number)
	begin
		declare @JobResponseID int,
		@WorkResponseID int
			
		select @JobResponseID = max(JobResponseID) from [dbo].[OpMaterialActual]
			where MaterialLotID = @F_number
		select @WorkResponseID = WorkResponse from [dbo].[JobResponse]
			where ID = @JobResponseID

		update [dbo].[WorkResponse]
		set EndTime = getdate()
			where ID = @WorkResponseID
end
else			 	
begin
insert into WorkResponse (
				Description,
				WorkType,
				StartTime
				) 
					values (
							@Op_Type,
							@Op_Type, GETDATE()
							)
insert into JobResponse (
				Description,
				WorkType,
				StartTime,
				WorkResponse
				)
					values (
							@Op_Type,
							@Op_Type, GETDATE(),
							(select max(ID) from WorkResponse)
							)
insert into OpMaterialActual(MaterialDefinitionID, MaterialLotID, JobResponseID, MaterialClassID)  	
		values ( 
			(select MaterialDefinitionID from MaterialLot where ID = @F_number), @F_number,
			(select max(ID) from JobResponse),
			(select MaterialClassID from MaterialDefinition where ID = (select MaterialDefinitionID from MaterialLot where ID = @F_number)))
	insert into MaterialActualProperty (Description, Value, OpMaterialActual) 
		values('Update Status', @status,
		(select max(ID) from OpMaterialActual))

end
update MaterialLot set Status=@status 
	where ID = @F_number
end
go