CREATE TABLE [yam3].[m_vereinsheim]
(
    [vereinsheim_id] INT           NOT NULL IDENTITY(1,1),
    [name]           NVARCHAR(200) NOT NULL,
    [adresse_id]     INT           NOT NULL,
    [ygrp_id]        INT           NOT NULL,
    [erstellt_am]    DATETIME2     NOT NULL CONSTRAINT [df_m_vereinsheim_erstellt] DEFAULT (SYSUTCDATETIME()),
    [erstellt_von]   NVARCHAR(100) NOT NULL,
    CONSTRAINT [pk_m_vereinsheim]         PRIMARY KEY CLUSTERED ([vereinsheim_id] ASC),
    CONSTRAINT [fk_m_vereinsheim_adresse] FOREIGN KEY ([adresse_id]) REFERENCES [yam3].[m_adresse] ([adresse_id]),
    CONSTRAINT [fk_m_vereinsheim_ygrp]    FOREIGN KEY ([ygrp_id])    REFERENCES [yam3].[d_ygrp]    ([id])
);
