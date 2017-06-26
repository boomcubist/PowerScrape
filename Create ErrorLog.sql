USE [PowerScrape]
GO

/****** Object:  Table [ps].[ErrorLog]    Script Date: 26/06/2017 15:23:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ps].[ErrorLog](
	[ErrorLogID] [int] IDENTITY(1,1) NOT NULL,
	[Routine] [varchar](50) NULL,
	[CapturedUrlID] [bigint] NOT NULL,
	[StatusCode] [nvarchar](5) NOT NULL,
	[ErrorMessage] [varchar](1000) NOT NULL,
	[DateLogged] [datetime] NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[ErrorLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


