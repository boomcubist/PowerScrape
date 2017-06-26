USE [PowerScrape]
GO

/****** Object:  Table [ps].[CapturedUrl]    Script Date: 26/06/2017 15:22:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ps].[CapturedUrl](
	[CapturedID] [int] IDENTITY(1,1) NOT NULL,
	[Url] [varchar](2000) NOT NULL,
	[Captured] [bit] NOT NULL,
	[DateCaptured] [datetime] NULL,
	[ReCaptured] [int] NOT NULL,
	[DateReCaptured] [datetime] NULL,
	[Scraped] [bit] NOT NULL,
	[DateScraped] [datetime] NULL,
	[ReScraped] [int] NOT NULL,
	[DateReScraped] [datetime] NULL,
	[Matched] [bit] NOT NULL,
	[DateMatched] [datetime] NULL,
 CONSTRAINT [PK_CapturedURL] PRIMARY KEY CLUSTERED 
(
	[CapturedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [ps].[CapturedUrl] ADD  CONSTRAINT [DF_CapturedUrl_Captured]  DEFAULT ((0)) FOR [Captured]
GO

ALTER TABLE [ps].[CapturedUrl] ADD  CONSTRAINT [DF_CapturedURL_ReCaptured]  DEFAULT ((0)) FOR [ReCaptured]
GO

ALTER TABLE [ps].[CapturedUrl] ADD  CONSTRAINT [DF_CapturedURL_Scraped]  DEFAULT ((0)) FOR [Scraped]
GO

ALTER TABLE [ps].[CapturedUrl] ADD  CONSTRAINT [DF_CapturedURL_ReScraped]  DEFAULT ((0)) FOR [ReScraped]
GO

ALTER TABLE [ps].[CapturedUrl] ADD  CONSTRAINT [DF_CapturedURL_Matched]  DEFAULT ((0)) FOR [Matched]
GO


