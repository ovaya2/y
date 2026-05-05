CREATE TABLE [yam3].[x_gl_adresse]
(
    [gl_adresse_id] INT           NOT NULL IDENTITY(1,1),
    [gl_id]         INT           NOT NULL,
    [adresse_id]    INT           NOT NULL,
    [gueltig_von]   DATE          NOT NULL,
    [gueltig_bis]   DATE          NULL,
    [geaendert_am]  DATETIME2     NOT NULL CONSTRAINT [df_x_gl_adresse_geaendert] DEFAULT (SYSUTCDATETIME()),
    [geaendert_von] NVARCHAR(100) NOT NULL,
    CONSTRAINT [pk_x_gl_adresse]         PRIMARY KEY CLUSTERED ([gl_adresse_id] ASC),
    CONSTRAINT [fk_x_gl_adresse_gl]      FOREIGN KEY ([gl_id])      REFERENCES [yam3].[m_gl]      ([id]),
    CONSTRAINT [fk_x_gl_adresse_adresse] FOREIGN KEY ([adresse_id]) REFERENCES [yam3].[m_adresse] ([adresse_id]),
    CONSTRAINT [ck_x_gl_adresse_zeitraum]
        CHECK ([gueltig_bis] IS NULL OR [gueltig_bis] >= [gueltig_von])
);

-- Max. eine aktive Adresse pro Mitglied (gueltig_bis IS NULL = aktuell gültig)
CREATE UNIQUE INDEX [uq_x_gl_adresse_aktiv]
    ON [yam3].[x_gl_adresse] ([gl_id])
    WHERE [gueltig_bis] IS NULL;

CREATE INDEX [ix_x_gl_adresse_zeitraum]
    ON [yam3].[x_gl_adresse] ([gl_id], [gueltig_von], [gueltig_bis]);
