USE [KRR-PA-ISA95_PRODUCTION]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'dbo.MTList', N'U') IS NULL 
begin
CREATE TABLE [dbo].[MTList](
	[IDMTList] [int] IDENTITY(1,1) NOT NULL,
	[IDMTSostav] [int] NOT NULL,
	[Position] [int] NOT NULL,
	[CarriageNumber] [int] NOT NULL,
	[CountryCode] [int] NOT NULL,
	[Weight] [real] NOT NULL,
	[IDCargo] [int] NOT NULL,
	[Cargo] [nvarchar](50) NOT NULL,
	[IDStation] [int] NOT NULL,
	[Station] [nvarchar](50) NOT NULL,
	[Consignee] [int] NOT NULL,
	[Operation] [nvarchar](50) NOT NULL,
	[CompositionIndex] [nvarchar](50) NOT NULL,
	[DateOperation] [datetime] NOT NULL,
	[TrainNumber] [int] NOT NULL,
	[NaturList] [int] NULL,
 CONSTRAINT [PK_MTList] PRIMARY KEY CLUSTERED 
(
	[IDMTList] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
end
GO

/****** Object:  Table [RailWay].[MTSostav]    Script Date: 11.10.2016 14:44:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID (N'dbo.MTSostav', N'U') IS NULL 
begin
CREATE TABLE [dbo].[MTSostav](
	[IDMTSostav] [int] IDENTITY(1,1) NOT NULL,
	[FileName] [nvarchar](50) NOT NULL,
	[CompositionIndex] [nvarchar](50) NOT NULL,
	[DateTime] [datetime] NOT NULL,
	[Operation] [int] NOT NULL,
	[Create] [datetime] NOT NULL,
	[Close] [datetime] NULL,
	[ParentID] [int] NULL,
 CONSTRAINT [PK_MTSostav] PRIMARY KEY CLUSTERED 
(
	[IDMTSostav] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
end
GO
IF OBJECT_ID (N'FK_MTList_MTSostav', N'F') IS NULL 
begin
	ALTER TABLE [dbo].[MTList]  WITH CHECK ADD  CONSTRAINT [FK_MTList_MTSostav] FOREIGN KEY([IDMTSostav])
	REFERENCES [dbo].[MTSostav] ([IDMTSostav])

	ALTER TABLE [dbo].[MTList] CHECK CONSTRAINT [FK_MTList_MTSostav]

end
GO




