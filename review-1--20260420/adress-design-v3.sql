-- ═══════════════════════════════════════════════════════════════════
-- yam2 — Adress-Infrastruktur v3
-- ═══════════════════════════════════════════════════════════════════
-- Stand:      2026-04-20
-- Zweck:      DDL für neue Tabellen der Adress-Infrastruktur
-- Schema:     [yam3] auf SauerSQL2.ovaya_test
-- Ziel:       Deployment via SSDT / DACPAC (DB-Projekt siehe db-projekt-setup.md)
-- ═══════════════════════════════════════════════════════════════════


-- ─── 1. LOOKUPS ─────────────────────────────────────────────────────

-- d_land | ISO-Länder
CREATE TABLE [yam3].[d_land] (
    land_id       INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_d_land PRIMARY KEY,
    iso_code      CHAR(2)       NOT NULL,                                  -- DE, AT, CH
    bezeichnung   NVARCHAR(100) NOT NULL,
    plz_regex     NVARCHAR(100)     NULL,                                  -- ^\d{5}$ für DE
    CONSTRAINT uq_d_land_iso UNIQUE (iso_code)
);

-- d_ort | PLZ/Ort länderabhängig
CREATE TABLE [yam3].[d_ort] (
    ort_id        INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_d_ort PRIMARY KEY,
    land_id       INT           NOT NULL CONSTRAINT fk_d_ort_land REFERENCES [yam3].[d_land](land_id),
    plz           VARCHAR(10)   NOT NULL,
    ort           NVARCHAR(100) NOT NULL,
    bundesland    NVARCHAR(50)      NULL,
    CONSTRAINT uq_d_ort_kombi UNIQUE (land_id, plz, ort)
);
CREATE INDEX ix_d_ort_plz ON [yam3].[d_ort] (plz);
GO


-- ─── 2. ADRESS-KERN ─────────────────────────────────────────────────

-- m_adresse | Adress-Stammdaten (IMMUTABLE, wiederverwendbar für Haushalt)
CREATE TABLE [yam3].[m_adresse] (
    adresse_id    INT            NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_adresse PRIMARY KEY,
    strasse       NVARCHAR(100)  NOT NULL,
    hausnummer    NVARCHAR(10)       NULL,                                  -- NULL zulässig (Postfach etc.)
    adresszusatz  NVARCHAR(100)  NOT NULL CONSTRAINT df_m_adresse_zusatz DEFAULT '',
    ort_id        INT            NOT NULL CONSTRAINT fk_m_adresse_ort REFERENCES [yam3].[d_ort](ort_id),
    erstellt_am   DATETIME2      NOT NULL CONSTRAINT df_m_adresse_erstellt DEFAULT SYSUTCDATETIME(),
    erstellt_von  NVARCHAR(100)  NOT NULL,
    CONSTRAINT ck_m_adresse_mindestangabe
        CHECK (hausnummer IS NOT NULL OR LEN(adresszusatz) > 0)
);

-- Dedupe: physisch identische Adressen nur einmal
CREATE UNIQUE INDEX uq_m_adresse_physisch
    ON [yam3].[m_adresse] (strasse, hausnummer, ort_id, adresszusatz);
GO

-- Immutable-Garantie: Direkt-UPDATE verbieten, Korrektur nur via SP
CREATE TRIGGER [yam3].[tr_m_adresse_immutable]
ON [yam3].[m_adresse]
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Nur ein dedizierter Session-Kontext (CONTEXT_INFO) darf updaten
    IF CONTEXT_INFO() <> CAST('adresse_korrektur' AS VARBINARY(128))
    BEGIN
        RAISERROR('m_adresse ist immutable. Korrekturen nur über sp_adresse_korrigieren.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE a
    SET strasse      = i.strasse,
        hausnummer   = i.hausnummer,
        adresszusatz = i.adresszusatz,
        ort_id       = i.ort_id
    FROM [yam3].[m_adresse] a
    INNER JOIN inserted i ON a.adresse_id = i.adresse_id;
END;
GO


-- x_gl_adresse | Zuordnung Mitglied ↔ Adresse mit Historie
-- Junction-Pattern (x_) da reine Verknüpfung mit Zeitbezug
CREATE TABLE [yam3].[x_gl_adresse] (
    gl_adresse_id    INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_x_gl_adresse PRIMARY KEY,
    gl_id            INT           NOT NULL CONSTRAINT fk_x_gl_adresse_gl      REFERENCES [yam3].[m_gl](id),
    adresse_id       INT           NOT NULL CONSTRAINT fk_x_gl_adresse_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    gueltig_von      DATE          NOT NULL,
    gueltig_bis      DATE              NULL,                                  -- NULL = aktuell aktiv
    geaendert_am     DATETIME2     NOT NULL CONSTRAINT df_x_gl_adresse_geaendert DEFAULT SYSUTCDATETIME(),
    geaendert_von    NVARCHAR(100) NOT NULL,
    CONSTRAINT ck_x_gl_adresse_zeitraum
        CHECK (gueltig_bis IS NULL OR gueltig_bis >= gueltig_von)
);

-- Max. eine aktive Adresse pro Mitglied (Filter-Index auf NULL)
CREATE UNIQUE INDEX uq_x_gl_adresse_aktiv
    ON [yam3].[x_gl_adresse] (gl_id)
    WHERE gueltig_bis IS NULL;

-- Query "Adresse zum Datum X": schnell
CREATE INDEX ix_x_gl_adresse_zeitraum
    ON [yam3].[x_gl_adresse] (gl_id, gueltig_von, gueltig_bis);
GO


-- ─── 3. VEREINS-OBJEKTE ─────────────────────────────────────────────

-- m_sportstaette | Sportstätte / Veranstaltungsort
CREATE TABLE [yam3].[m_sportstaette] (
    sportstaette_id   INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_sportstaette PRIMARY KEY,
    bezeichnung       NVARCHAR(200) NOT NULL,
    beschreibung      NVARCHAR(500)     NULL,                                -- "Handball, Turnen, Hallenfußball"
    adresse_id        INT           NOT NULL CONSTRAINT fk_m_sportstaette_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    ist_vereinseigen  BIT           NOT NULL CONSTRAINT df_m_sportstaette_eigen DEFAULT 0
);
GO

-- m_vereinsheim | Vereinsheim als eigene Entity (erweiterbar: Kapazität, Hausmeister etc.)
CREATE TABLE [yam3].[m_vereinsheim] (
    vereinsheim_id  INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_vereinsheim PRIMARY KEY,
    name            NVARCHAR(200) NOT NULL,
    adresse_id      INT           NOT NULL CONSTRAINT fk_m_vereinsheim_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    ygrp_id         INT           NOT NULL CONSTRAINT fk_m_vereinsheim_ygrp    REFERENCES [yam3].[d_ygrp](id)
);
GO


-- ─── 4. ERWEITERUNG BESTEHENDER TABELLEN ────────────────────────────

-- d_ygrp bekommt Vereinssitz
ALTER TABLE [yam3].[d_ygrp]
    ADD vereinssitz_adresse_id INT NULL
        CONSTRAINT fk_d_ygrp_vereinssitz REFERENCES [yam3].[m_adresse](adresse_id);
GO


-- ─── 5. SEED: MINIMAL ───────────────────────────────────────────────

-- Länder-Basis (kann später erweitert werden)
INSERT INTO [yam3].[d_land] (iso_code, bezeichnung, plz_regex) VALUES
    ('DE', 'Deutschland', '^\d{5}$'),
    ('AT', 'Österreich',  '^\d{4}$'),
    ('CH', 'Schweiz',     '^\d{4}$');
GO


-- ═══════════════════════════════════════════════════════════════════
-- Hinweise zur Nutzung
-- ═══════════════════════════════════════════════════════════════════
-- - m_adresse ist IMMUTABLE: neue Adresse = neue Zeile
-- - Dedupe passiert im Repository: gleiche (strasse, hausnr, ort, zusatz) → adresse_id wiederverwenden
-- - Korrekturen (Tippfehler) nur via SP 'sp_adresse_korrigieren' (setzt CONTEXT_INFO vor UPDATE)
-- - Austritt eines Mitglieds ändert Adresse NICHT — gueltig_bis bleibt NULL
-- - DSGVO-Löschung: m_gl-Personendaten anonymisieren, m_adresse bleibt (gehört zum Gebäude)
