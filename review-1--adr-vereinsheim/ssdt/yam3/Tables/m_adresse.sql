CREATE TABLE [yam3].[m_adresse]
(
    [adresse_id]   INT           NOT NULL IDENTITY(1,1),
    [strasse]      NVARCHAR(100) NOT NULL,
    [hausnummer]   NVARCHAR(10)  NULL,
    [adresszusatz] NVARCHAR(100) NOT NULL CONSTRAINT [df_m_adresse_zusatz]    DEFAULT (''),
    [ort_id]       INT           NOT NULL,
    [erstellt_am]  DATETIME2     NOT NULL CONSTRAINT [df_m_adresse_erstellt]  DEFAULT (SYSUTCDATETIME()),
    [erstellt_von] NVARCHAR(100) NOT NULL,
    CONSTRAINT [pk_m_adresse]              PRIMARY KEY CLUSTERED ([adresse_id] ASC),
    CONSTRAINT [fk_m_adresse_ort]          FOREIGN KEY ([ort_id]) REFERENCES [yam3].[d_ort] ([ort_id]),
    CONSTRAINT [ck_m_adresse_mindestangabe]
        CHECK ([hausnummer] IS NOT NULL OR LEN([adresszusatz]) > 0)
);

CREATE UNIQUE INDEX [uq_m_adresse_physisch]
    ON [yam3].[m_adresse] ([strasse], [hausnummer], [ort_id], [adresszusatz]);
