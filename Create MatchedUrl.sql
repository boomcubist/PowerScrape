USE [PowerScrape]
GO

/****** Object:  Table [ps].[MatchedUrl]    Script Date: 26/06/2017 15:23:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ps].[MatchedUrl](
	[MatchedID] [int] IDENTITY(1,1) NOT NULL,
	[CapturedUrlID] [int] NOT NULL,
	[SearchTermID] [varchar](200) NOT NULL,
	[DateMatched] [datetime] NULL,
 CONSTRAINT [PK_MatchedURL] PRIMARY KEY CLUSTERED 
(
	[MatchedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


