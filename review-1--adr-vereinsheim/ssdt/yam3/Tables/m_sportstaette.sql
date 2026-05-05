CREATE TABLE [yam3].[m_sportstaette]
(
    [sportstaette_id]  INT           NOT NULL IDENTITY(1,1),
    [bezeichnung]      NVARCHAR(200) NOT NULL,
    [beschreibung]     NVARCHAR(500) NULL,
    [adresse_id]       INT           NOT NULL,
    [ist_vereinseigen] BIT           NOT NULL CONSTRAINT [df_m_sportstaette_eigen]    DEFAULT (0),
    [erstellt_am]      DATETIME2     NOT NULL CONSTRAINT [df_m_sportstaette_erstellt] DEFAULT (SYSUTCDATETIME()),
    [erstellt_von]     NVARCHAR(100) NOT NULL,
    CONSTRAINT [pk_m_sportstaette]         PRIMARY KEY CLUSTERED ([sportstaette_id] ASC),
    CONSTRAINT [fk_m_sportstaette_adresse] FOREIGN KEY ([adresse_id]) REFERENCES [yam3].[m_adresse] ([adresse_id])
);
