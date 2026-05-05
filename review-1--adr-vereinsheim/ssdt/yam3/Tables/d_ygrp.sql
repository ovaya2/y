-- ACHTUNG: Diese Datei ersetzt die bestehende yam3/Tables/d_ygrp.sql im SSDT-Projekt.
-- Änderung: vereinssitz_adresse_id (FK auf m_adresse) ergänzt.

CREATE TABLE [yam3].[d_ygrp]
(
    [id]                     INT          NOT NULL IDENTITY(1,1),
    [bez]                    NVARCHAR(50) NOT NULL,
    [vereinssitz_adresse_id] INT          NULL,
    CONSTRAINT [pk_d_ygrp]             PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [fk_d_ygrp_vereinssitz] FOREIGN KEY ([vereinssitz_adresse_id])
        REFERENCES [yam3].[m_adresse] ([adresse_id])
);
