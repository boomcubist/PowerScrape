USE [PowerScrape]
GO

/****** Object:  Table [ps].[SearchTerms]    Script Date: 26/06/2017 15:23:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ps].[SearchTerms](
	[SearchTermID] [int] IDENTITY(1,1) NOT NULL,
	[TermDescription] [varchar](100) NOT NULL,
	[AssociatedDomain] [varchar](100) NULL,
	[Category] [varchar](25) NOT NULL,
 CONSTRAINT [PK_SearchTerms] PRIMARY KEY CLUSTERED 
(
	[SearchTermID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


