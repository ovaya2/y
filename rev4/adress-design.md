<!-- adress-design.md — v4.2.0 — Doku-Nachzug: Namen nach Umbenennung (E-004, E-009, E-011), ist_sitz umgesetzt (E-001), vereinssitz_adresse_id entfernt, DDL §4.4 aus dem Datenbankprojekt (Commit d1dfd1b), Stand der Umsetzung (§10) -->
<!-- vorher: adress-design.md — v4.1.0 — Korrekturen aus eigener Prüfung: Overlap-Trigger (halb-offen), Immutable-Trigger (NULL-Fall), CHECK (bis > von); ist_sitz als abhängig von §7 #7 markiert; §7 #2 entschieden -->
# yam2 — Adress-Infrastruktur

**Stand:** 12.10.2026 (v4.2; Datenbankprojekt im Stand Commit `d1dfd1b`, Branch `feature/gruppe-sitzspalte-entfernen`)
**Version:** 4.2 — v4.1 + Nachzug der Namen und des Umsetzungsstands
**Autor:** Ovaya

Adress-Infrastruktur für yam2. Anforderung aus Teams-Gespräch 20.04.2026, Review-Feedback 06.05.2026.

> **Neu in v4.2** (Details in §9, Zuordnung der Namen in §4.5, Umsetzungsstand in §10):
> - Namen an das Datenbankprojekt angepasst: `m_mitglied`, `mitglied_id`, `x_mitglied_adresse`, `d_gruppe`, `x_objekt_gruppe`, `m_objekt.bezeichnung`, Trigger `tr_x_mitglied_adresse_no_overlap`
> - `ist_sitz` ist umgesetzt (Entscheidung zu §7 #7: Flag an `m_objekt` mit Filter-Unique-Index `uq_m_objekt_sitz`)
> - `d_gruppe.vereinssitz_adresse_id` ist aus dem Projekt entfernt
> - §4.4 (DDL) besteht jetzt aus den Dateien des Datenbankprojekts, nicht mehr aus einem handgeschriebenen Skript
> - Feldnamen in UC-11 und §3 entsprechen dem Stand nach der Umbenennung
> - Neu: §10 Stand der Umsetzung je Punkt aus Ginos Feedback
> - Entscheidungen zu §7 #1, #2, #7, #8, #9 sind getroffen (§7); #3 bis #6 sind weiter offen
> - Die Korrekturen V1 bis V5 aus v4.1 sind im Projekt umgesetzt (§9)

---

## 📋 Inhalt

1. [Kontext & Auftrag](#1-kontext--auftrag)
2. [Anwendungsfälle](#2-anwendungsfälle)
3. [Logik-Entscheidungen](#3-logik-entscheidungen)
4. [DB-Design](#4-db-design)
5. [Migrations-Pfad](#5-migrations-pfad)
6. [Optionale Erweiterungen](#6-optionale-erweiterungen)
7. [Offene Entscheidungen](#7-offene-entscheidungen)
8. [Nicht-Ziele](#8-nicht-ziele)
9. [Änderungsprotokoll v3 → v4 → v4.1 → v4.2](#9-änderungsprotokoll-v3--v4--v41--v42)
10. [Stand der Umsetzung](#10-stand-der-umsetzung)

---

## 1. Kontext & Auftrag

<details>
<summary>Anforderungen aus den Teams-Gesprächen</summary>

Vorgaben aus dem Gespräch vom **20.04.2026**:

- Die Gruppe (`d_gruppe`, damals `d_ygrp`) soll die Möglichkeit haben, ein Vereinsheim zu definieren
- Der Verein braucht einen Sitz
- Sportstätten sind Orte, an denen bestimmte Tätigkeiten stattfinden (Beispiel: Handball, Turnen in Sporthalle Beispielstraße 3)
- Anwendungsfälle und Logik zusammenschreiben — insbesondere Historisierung und mehrere Mitglieder an gleicher Adresse
- Erst Design, dann Implementierung
- Reihenfolge: Kundenanforderung → Functional Specs → Technical Specs → DB-Design → Implementierung

Folgegespräch vom **06.05.2026** (Review zu v3):

- PLZ als VARCHAR + Intervall-Modell — bestätigt
- UC-6 Sportstätte: verknüpfungstechnisch leer in v3, muss ergänzt werden
- Vereinsheim und Sportstätte sind technisch verwandt — zusammenführen, Trennung erst nachgelagert über Erweiterungen
- Intervall-Überlappung muss im DDL geschützt sein — UNIQUE-Index allein reicht nicht
- Whitespace-Normalisierung als optionale Verbesserung

</details>

---

## 2. Anwendungsfälle

<details>
<summary>13 Fälle — UC-1 bis UC-13</summary>

| Nr | Fall | Essenz |
|---|---|---|
| UC-1 | Mitglied-Standardadresse | Eine aktive Adresse pro Mitglied — für Etikett, Verzeichnis, Mahnbrief |
| UC-2 | Adresse ändert sich ab Datum X | Umzug mit Historisierung, Wirksamkeit ab Datum |
| UC-3 | Haushalt — mehrere Mitglieder gleiche Adresse | Familie pflegt eine Adresse, keine Redundanz |
| UC-4 | Vereinssitz | Offizielle Adresse des Vereins (laut Register) |
| UC-5 | Vereinsheim | Eigenes Objekt des Vereins mit Adresse und Name |
| UC-6 | Sportstätte | Ort für Aktivität mit Beschreibung ("Handball in Sporthalle …") |
| UC-7 | Haushalts-Umzug | Familie zieht gemeinsam, ein Arbeitsschritt für alle |
| UC-8 | Auszug aus Haushalt | Einer zieht aus, andere bleiben an alter Adresse |
| UC-9 | Internationale Mitglieder | AT/CH möglich, PLZ variable Länge |
| UC-10 | DSGVO-Auskunft | Vollständige Adress-Historie abrufbar |
| UC-11 | DSGVO-Löschung | Personendaten in `m_mitglied` anonymisieren: `vorname`, `nachname`, `geburtsdatum`, `email`, `telefon`, `iban`, `bic`, `sepa_referenz`, `sepa_datum` → Platzhalter; `dsgvo_einwilligung_daten`, `dsgvo_einwilligung_foto` → 0. `m_adresse` bleibt unberührt (gebäudebezogen) |
| UC-12 | Mahnbrief historisch | Adresse zum Fälligkeitsdatum verwenden |
| UC-13 | Austritt | Adress-Zuordnung bleibt aktiv; Mitgliedschafts-Status wird über bestehendes `d_status` abgebildet. Datenschutz-Einschränkungen (Art. 18 DSGVO) sind nicht Teil dieses Designs |

> **Hinweis v4.2:** Die Feldnamen in UC-11 und in der DSGVO-Zeile in §3 entsprechen dem Datenbankprojekt nach der Umbenennung der Kürzel (§7 #2, Zuordnung in §4.5).

</details>

---

## 3. Logik-Entscheidungen

<details>
<summary>18 Entscheidungen mit Begründung</summary>

| Thema | Entscheidung | Begründung |
|---|---|---|
| Mehrere Adressen parallel | Nein, genau eine aktive pro Mitglied | Komplexität ohne Vereins-Nutzen |
| Historisierung-Ort | Separate Zuordnungstabelle `x_mitglied_adresse` | Mitglied-Stammdaten bleiben sauber |
| Adress-Datensatz | Immutable per Trigger | Historie sonst inkonsistent |
| Tippfehler-Korrektur | Eigene SP `sp_adresse_korrigieren` | Einziger legitimer Änderungs-Pfad |
| Umzug vs. Korrektur | Zwei getrennte Fach-Operationen | Semantische Klarheit |
| Haushalt-Konzept | Implizit über geteilte `adresse_id` | Kein eigener Typ nötig |
| Haushalts-Umzug | Eigene Operation `MoveHousehold` | Atomar für alle betroffenen Mitglieder |
| Austritt | Mitgliedschafts-Status über bestehendes `d_status`, Adress-Zuordnung bleibt aktiv | Statusmechanismus ist bereits implementiert; DSGVO-Einschränkung der Verarbeitung ist separates Modul |
| DSGVO-Löschung | Felder `vorname`, `nachname`, `geburtsdatum`, `email`, `telefon`, `iban`, `bic`, `sepa_referenz`, `sepa_datum` → Platzhalter; `dsgvo_einwilligung_daten`/`dsgvo_einwilligung_foto` → 0; `m_adresse` bleibt | AO §147 (10 Jahre); Adresse ist gebäudebezogen. Feldnamen entsprechen dem Datenbankprojekt (Stand `d1dfd1b`). |
| Gültigkeits-Intervall | Halb-offen `[gueltig_von, gueltig_bis)` | `gueltig_bis` ist erster Tag ohne Gültigkeit — verhindert Grenzfall-Duplikate bei Abfragen zum Stichtag |
| **Intervall-Überlappung** | **Doppelte Absicherung: Filter-Unique-Index + AFTER-Trigger** | Filter-Unique-Index deckt nur den NULL-Fall ab; geschlossene Intervalle können trotzdem überlappen. |
| Land-Support | `d_land` Lookup mit PLZ-Regex | Internationale Mitglieder möglich |
| PLZ-Feld | `VARCHAR(10)` | DE 5 / AT 4 / CH 4 / GB bis 8 alphanum. |
| Hausnummer | NULL zulässig mit CHECK-Constraint | Postfach, "an der alten Mühle" |
| **Vereinsobjekte** | **Gemeinsame Basis `m_objekt` mit Typ-Lookup `d_objekttyp` (Vereinsheim, Sportstätte, Lager, Sonstige)** | Vereinsheim und Sportstätte teilen Bezeichnung, Adresse, Audit, Aktiv-Flag. Spezialisierung über `m_objekt_extra` oder Subtypen ist nachrüstbar. |
| **Vereinssitz** | **Flag `ist_sitz` an `m_objekt` mit Filter-Unique-Index `uq_m_objekt_sitz` (`WHERE ist_sitz = 1`)** | Die Datenbank erzwingt „höchstens ein Sitz“ selbst. Annahme: eine Datenbank = ein Verein. Nächste Alternative: eigener Objekttyp „Vereinssitz“. |
| **Sportstätten-Verknüpfung** | **N:M-Junction `x_objekt_gruppe` mit Beschreibungs-Spalte** | Eine Halle beherbergt mehrere Sportarten, eine Sportart läuft an mehreren Orten. Beschreibung ("Dienstag 18-20") gehört in die Verknüpfung, nicht in die Stammdaten der Sportstätte. |
| Sportstätten-Buchung | Nicht in diesem Design | Eigenes Modul, nicht beauftragt |

</details>

---

## 4. DB-Design

<details>
<summary>Tabellen, Beziehungen, vollständige DDL, Namen alt → neu</summary>

### 4.1 Tabellen-Übersicht

| Tabelle | Rolle | Stand im Datenbankprojekt (`d1dfd1b`) |
|---|---|---|
| `d_land` | Lookup: Länder + PLZ-Regex | vorhanden |
| `d_ort` | Lookup: PLZ/Ort länderabhängig | vorhanden |
| `m_adresse` | Adress-Stammdaten (immutable) | vorhanden |
| `x_mitglied_adresse` | Zuordnung Mitglied ↔ Adresse + Historie | vorhanden (Dateiname `x_gl_adresse.sql`) |
| `d_objekttyp` | Lookup: Typ eines Vereinsobjekts | vorhanden |
| `m_objekt` | Vereinsobjekte (Vereinsheim, Sportstätte, …) mit Flag `ist_sitz` | vorhanden |
| `x_objekt_gruppe` | Junction Objekt ↔ Gruppe + Beschreibung | vorhanden |
| `m_objekt_extra` | Schlüssel-Wert-Erweiterung pro Objekt | OPTIONAL — nicht umgesetzt (§6.2) |

> Hinweis: Die in v3 vorgesehene Spalte `vereinssitz_adresse_id` an der Gruppentabelle entfällt seit v4. Seit v4.2 ist sie auch aus dem Datenbankprojekt entfernt (Spalte und Fremdschlüssel `fk_d_ygrp_vereinssitz`). Der Vereinssitz steht in `m_objekt.ist_sitz`. Zum Stand auf der Team-Datenbank siehe §10.

### 4.2 Beziehungen

```
d_land ◄── d_ort ◄── m_adresse ◄── x_mitglied_adresse ──► m_mitglied
                          ▲
                          │
d_objekttyp ◄── m_objekt ─┘
                  ▲
                  │
                  └── x_objekt_gruppe ──► d_gruppe
```

### 4.3 Zentrale Konstrukte

- Filter-Unique-Index `uq_x_gl_adresse_aktiv WHERE gueltig_bis IS NULL` — max. eine offene Gültigkeit pro Mitglied
- **Trigger `tr_x_mitglied_adresse_no_overlap`** — verhindert sich überlappende geschlossene Intervalle; Bedingung für das halb-offene Intervall `[von, bis)` (V1)
- CHECK-Constraint `ck_x_gl_adresse_zeitraum` — `gueltig_bis > gueltig_von`, ein leerer Zeitraum ist nicht erlaubt (V3)
- Immutable-Trigger `tr_m_adresse_immutable` — UPDATE auf `m_adresse` nur via `sp_adresse_korrigieren` mit `CONTEXT_INFO`; NULL-Fall (nie gesetzt) abgesichert (V2)
- CHECK-Constraint `ck_m_adresse_mindestangabe` — Hausnummer oder Adresszusatz gesetzt
- Dedupe-Index `uq_m_adresse_physisch` — identische Adressen nur einmal
- Filter-Unique-Index `uq_m_objekt_sitz WHERE ist_sitz = 1` — höchstens ein Vereinssitz

Constraint- und Indexnamen der Tabelle `x_mitglied_adresse` tragen noch den früheren Tabellennamen (`pk_x_gl_adresse`, `uq_x_gl_adresse_aktiv`, `ix_x_gl_adresse_zeitraum`, `ck_x_gl_adresse_zeitraum`, `fk_x_gl_adresse_gl`, `fk_x_gl_adresse_adresse`): Sie sollen gebündelt in einer eigenen Umbenennung angepasst werden, bis dahin gelten diese Namen.

### 4.4 Vollständige DDL

Die Blöcke sind die Dateien des Datenbankprojekts `yam2.Database` im Stand Commit `d1dfd1b` (Branch `feature/gruppe-sitzspalte-entfernen`), im Inhalt unverändert übernommen (nur das Byte-Order-Mark der Seed-Datei ist weggelassen). In v4.1 stand hier ein handgeschriebenes Skript, das vom Projekt abwich (Namen, `ist_sitz`, benannte Constraints); Abweichungen siehe §9.

<details>
<summary>SQL-Dateien einblenden</summary>

**1. Lookups**

Datei `yam2.Database/yam3/Tables/d_land.sql`

```sql
CREATE TABLE [yam3].[d_land]
(
    [land_id]     INT           NOT NULL IDENTITY(1,1),
    [iso_code]    CHAR(2)       NOT NULL,
    [bezeichnung] NVARCHAR(100) NOT NULL,
    [plz_regex]   NVARCHAR(100) NULL,
    CONSTRAINT [pk_d_land]     PRIMARY KEY CLUSTERED ([land_id] ASC),
    CONSTRAINT [uq_d_land_iso] UNIQUE ([iso_code])
);
```

Datei `yam2.Database/yam3/Tables/d_ort.sql`

```sql
CREATE TABLE [yam3].[d_ort]
(
    [ort_id]     INT           NOT NULL IDENTITY(1,1),
    [land_id]    INT           NOT NULL,
    [plz]        VARCHAR(10)   NOT NULL,
    [ort]        NVARCHAR(100) NOT NULL,
    [bundesland] NVARCHAR(50)  NULL,
    CONSTRAINT [pk_d_ort]      PRIMARY KEY CLUSTERED ([ort_id] ASC),
    CONSTRAINT [fk_d_ort_land] FOREIGN KEY ([land_id]) REFERENCES [yam3].[d_land] ([land_id]),
    CONSTRAINT [uq_d_ort_kombi] UNIQUE ([land_id], [plz], [ort])
);
GO

CREATE INDEX [ix_d_ort_plz] ON [yam3].[d_ort] ([plz]);
```

Datei `yam2.Database/yam3/Tables/d_objekttyp.sql`

```sql
-- d_objekttyp.sql — v1.0.0 — Erstfassung (Sportstaetten SP2; DDL getestet in spike-sportstaetten.sql v1.0.0, 17/17 OK auf der Probe-DB)
--: d_objekttyp
-- WAS:         Lookup: Typ eines Vereinsobjekts (1 Vereinsheim, 2 Sportstaette, 3 Lager, 4 Sonstige). Seed: Scripts\d_objekttyp_seed.sql.
-- WARUM:       Vereinsheim und Sportstaette teilen Name, Adresse und Audit; sie werden ueber den Typ unterschieden
--              statt ueber zwei Tabellen (Ginos Rueckmeldung 06.05., Adress-Design v4.1 §3).
-- BEGRUENDUNG: objekttyp_id ohne IDENTITY, weil die IDs fest vergeben und spaeter an C# koppelbar sind (Muster d_anrede).
--              Weitere Typen bei konkretem Bedarf ergaenzen (Adress-Design v4.1 §7 #6).
CREATE TABLE [yam3].[d_objekttyp]
(
    [objekttyp_id] INT          NOT NULL,
    [bezeichnung]  NVARCHAR(50) NOT NULL,
    CONSTRAINT [pk_d_objekttyp]             PRIMARY KEY CLUSTERED ([objekttyp_id] ASC),
    CONSTRAINT [uq_d_objekttyp_bezeichnung] UNIQUE ([bezeichnung])
);
```

**2. Adress-Kern**

Datei `yam2.Database/yam3/Tables/m_adresse.sql`

```sql
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
GO

CREATE UNIQUE INDEX [uq_m_adresse_physisch]
    ON [yam3].[m_adresse] ([strasse], [hausnummer], [ort_id], [adresszusatz]);
```

Datei `yam2.Database/yam3/Triggers/tr_m_adresse_immutable.sql`

```sql
CREATE TRIGGER [yam3].[tr_m_adresse_immutable]
ON [yam3].[m_adresse]
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- CONTEXT_INFO() kann NULL sein (Initialzustand) → explizit prüfen,
    -- sonst wäre NULL <> 'adresse_korrektur' = NULL (= kein Fehler, Trigger bypassed)
    DECLARE @ctx VARBINARY(128) = CONTEXT_INFO();
    IF @ctx IS NULL OR @ctx <> CAST('adresse_korrektur' AS VARBINARY(128))
    BEGIN
        RAISERROR('m_adresse ist immutable. Korrekturen nur über sp_adresse_korrigieren.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE a
    SET    [strasse]      = i.[strasse],
           [hausnummer]   = i.[hausnummer],
           [adresszusatz] = i.[adresszusatz],
           [ort_id]       = i.[ort_id]
    FROM   [yam3].[m_adresse] a
    INNER JOIN inserted i ON a.[adresse_id] = i.[adresse_id];
END;
```

Datei `yam2.Database/yam3/Tables/x_gl_adresse.sql`

```sql
-- x_gl_adresse.sql — v1.1.0 — CHECK gueltig_bis > gueltig_von (v4.1 V3, halb-offenes Intervall)
CREATE TABLE [yam3].[x_mitglied_adresse]
(
    [mitglied_adresse_id] INT           NOT NULL IDENTITY(1,1),
    [mitglied_id]         INT           NOT NULL,
    [adresse_id]    INT           NOT NULL,
    [gueltig_von]   DATE          NOT NULL,
    [gueltig_bis]   DATE          NULL,
    [geaendert_am]  DATETIME2     NOT NULL CONSTRAINT [df_x_gl_adresse_geaendert] DEFAULT (SYSUTCDATETIME()),
    [geaendert_von] NVARCHAR(100) NOT NULL,
    CONSTRAINT [pk_x_gl_adresse]         PRIMARY KEY CLUSTERED ([mitglied_adresse_id] ASC),
    CONSTRAINT [fk_x_gl_adresse_gl]      FOREIGN KEY ([mitglied_id])      REFERENCES [yam3].[m_mitglied]      ([id]),
    CONSTRAINT [fk_x_gl_adresse_adresse] FOREIGN KEY ([adresse_id]) REFERENCES [yam3].[m_adresse] ([adresse_id]),
    -- Halb-offenes Intervall [von, bis): bis = von wäre ein leerer Zeitraum, deshalb strikt größer (v4.1 V3).
    CONSTRAINT [ck_x_gl_adresse_zeitraum]
        CHECK ([gueltig_bis] IS NULL OR [gueltig_bis] > [gueltig_von])
);
GO

-- Max. eine aktive Adresse pro Mitglied (gueltig_bis IS NULL = aktuell gültig)
CREATE UNIQUE INDEX [uq_x_gl_adresse_aktiv]
    ON [yam3].[x_mitglied_adresse] ([mitglied_id])
    WHERE [gueltig_bis] IS NULL;
GO

CREATE INDEX [ix_x_gl_adresse_zeitraum]
    ON [yam3].[x_mitglied_adresse] ([mitglied_id], [gueltig_von], [gueltig_bis]);
```

Datei `yam2.Database/yam3/Triggers/tr_x_mitglied_adresse_no_overlap.sql`

```sql
-- tr_x_mitglied_adresse_no_overlap.sql — v1.0.0
-- WAS:         Verhindert sich überlappende Gültigkeitszeiträume je Mitglied in [yam3].[x_mitglied_adresse].
-- WARUM:       Der Filter-Unique-Index uq_x_gl_adresse_aktiv erlaubt nur eine offene Zeile pro Mitglied.
--              Zwei geschlossene Zeiträume (oder offen gegen geschlossen) könnten sich sonst überlappen
--              (Ginos Hinweis 06.05., Adress-Design v4.1 §9 V1).
-- BEGRÜNDUNG:  Halb-offenes Intervall [gueltig_von, gueltig_bis): a.von < b.bis UND b.von < a.bis.
--              gueltig_bis ist der erste Tag ohne Gültigkeit, ein Umzug (alte Zeile bis = neue Zeile von)
--              bleibt deshalb erlaubt. Ein offenes Ende (NULL) zählt als 9999-12-31.
-- WIE:         AFTER INSERT, UPDATE. Prüft jedes Zeilenpaar einmal (a.mitglied_adresse_id < b.mitglied_adresse_id),
--              nur für Mitglieder aus [inserted]. Bei Treffer RAISERROR + ROLLBACK (Muster wie tr_m_adresse_immutable).
CREATE TRIGGER [yam3].[tr_x_mitglied_adresse_no_overlap]
ON [yam3].[x_mitglied_adresse]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- v4.1: Überlappung zweier halb-offener Intervalle [von, bis): a.von < b.bis UND b.von < a.bis.
    --       Die v4-Bedingung (<= / >=) behandelte gueltig_bis als eingeschlossen und hätte einen
    --       normalen Umzug (alte Zeile bis = neue Zeile von) als Überlappung abgelehnt (UC-2, UC-7).
    IF EXISTS (
        SELECT 1
        FROM [yam3].[x_mitglied_adresse] a
        JOIN [yam3].[x_mitglied_adresse] b
          ON a.[mitglied_id]          =  b.[mitglied_id]
         AND a.[mitglied_adresse_id]  <  b.[mitglied_adresse_id]                  -- jedes Paar nur einmal
         AND a.[gueltig_von]          <  ISNULL(b.[gueltig_bis], '9999-12-31')
         AND b.[gueltig_von]          <  ISNULL(a.[gueltig_bis], '9999-12-31')
        WHERE a.[mitglied_id] IN (SELECT [mitglied_id] FROM inserted)
    )
    BEGIN
        RAISERROR('Adress-Gültigkeitsintervalle überlappen sich für dieselbe mitglied_id.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
```

Datei `yam2.Database/yam3/Stored Procedures/sp_adresse_korrigieren.sql`

```sql
-- =============================================
-- 6. EXECUTE (Logik)
-- =============================================
-- Einziger zulaessiger Weg, eine Zeile in [yam3].[m_adresse] nachtraeglich zu aendern.
-- tr_m_adresse_immutable (INSTEAD OF UPDATE) lehnt jedes direkte UPDATE ab, ausser
-- CONTEXT_INFO() ist auf 'adresse_korrektur' gesetzt - genau das setzt diese Prozedur.
CREATE PROCEDURE [yam3].[sp_adresse_korrigieren]
    @adresse_id INT,
    @strasse NVARCHAR(100),
    @hausnummer NVARCHAR(10) = NULL,
    @adresszusatz NVARCHAR(100) = '',
    @ort_id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [yam3].[m_adresse] WHERE [adresse_id] = @adresse_id)
    BEGIN
        RAISERROR('sp_adresse_korrigieren: adresse_id %d nicht gefunden.', 16, 1, @adresse_id);
        RETURN;
    END;

    DECLARE @ctx VARBINARY(128) = CAST('adresse_korrektur' AS VARBINARY(128));

    BEGIN TRY
        SET CONTEXT_INFO @ctx;

        UPDATE [yam3].[m_adresse]
        SET [strasse]      = @strasse,
            [hausnummer]   = @hausnummer,
            [adresszusatz] = @adresszusatz,
            [ort_id]       = @ort_id
        WHERE [adresse_id] = @adresse_id;

        -- CONTEXT_INFO zuruecksetzen, damit das Bypass-Flag nicht auf einer aus dem
        -- ADO.NET-Connection-Pool wiederverwendeten Verbindung fuer spaetere,
        -- eigentlich unzulaessige UPDATEs bestehen bleibt.
        SET CONTEXT_INFO 0x00;
    END TRY
    BEGIN CATCH
        SET CONTEXT_INFO 0x00;
        THROW;
    END CATCH;
END;
```

**3. Vereinsobjekte**

Datei `yam2.Database/yam3/Tables/m_objekt.sql`

```sql
-- m_objekt.sql — v1.0.0 — Erstfassung (Sportstaetten SP2; DDL getestet in spike-sportstaetten.sql v1.0.0, 17/17 OK auf der Probe-DB)
--: m_objekt
-- WAS:         Vereinsobjekte (Vereinsheim, Sportstaette, Lager, Sonstige) in EINER Tabelle; der Typ steht in typ_id -> d_objekttyp.
-- WARUM:       Ginos Rueckmeldung 06.05.: Vereinsheim und Sportstaette sind technisch verwandt und werden zusammengefuehrt
--              (Adress-Design v4.1 §3). Loest m_sportstaette und m_vereinsheim (v3) ab.
-- BEGRUENDUNG: ist_sitz BIT + Filter-Unique-Index uq_m_objekt_sitz (E-001): hoechstens EIN Sitz pro Datenbank (eine DB = ein Verein).
--              Naechste Alternative: eigener d_objekttyp 'Vereinssitz'.
--              Spalte bezeichnung statt name (wie d_gruppe.bezeichnung, Welle 2). Naechste Alternative: name (wie in v4.1).
-- WIE:         Gruppen-Zuordnung ueber x_objekt_gruppe; Adresse ueber m_adresse (immutable, Trigger tr_m_adresse_immutable).
CREATE TABLE [yam3].[m_objekt]
(
    [objekt_id]        INT           NOT NULL IDENTITY(1,1),
    [bezeichnung]      NVARCHAR(100) NOT NULL,
    [typ_id]           INT           NOT NULL,
    [adresse_id]       INT           NOT NULL,
    [ist_sitz]         BIT           NOT NULL CONSTRAINT [df_m_objekt_sitz]     DEFAULT (0),
    [ist_vereinseigen] BIT           NOT NULL CONSTRAINT [df_m_objekt_eigen]    DEFAULT (0),
    [beschreibung]     NVARCHAR(500) NULL,
    [aktiv]            BIT           NOT NULL CONSTRAINT [df_m_objekt_aktiv]    DEFAULT (1),
    [erstellt_am]      DATETIME2     NOT NULL CONSTRAINT [df_m_objekt_erstellt] DEFAULT (SYSUTCDATETIME()),
    [erstellt_von]     NVARCHAR(100) NOT NULL,
    [geaendert_am]     DATETIME2     NULL,
    [geaendert_von]    NVARCHAR(100) NULL,
    CONSTRAINT [pk_m_objekt]         PRIMARY KEY CLUSTERED ([objekt_id] ASC),
    CONSTRAINT [fk_m_objekt_typ]     FOREIGN KEY ([typ_id])     REFERENCES [yam3].[d_objekttyp] ([objekttyp_id]),
    CONSTRAINT [fk_m_objekt_adresse] FOREIGN KEY ([adresse_id]) REFERENCES [yam3].[m_adresse]   ([adresse_id])
);
GO

CREATE UNIQUE INDEX [uq_m_objekt_sitz]
    ON [yam3].[m_objekt] ([ist_sitz])
    WHERE [ist_sitz] = 1;
```

Datei `yam2.Database/yam3/Tables/x_objekt_gruppe.sql`

```sql
-- x_objekt_gruppe.sql — v1.0.0 — Erstfassung (Sportstaetten SP2; DDL getestet in spike-sportstaetten.sql v1.0.0, 17/17 OK auf der Probe-DB)
--: x_objekt_gruppe
-- WAS:         N:M-Verknuepfung Vereinsobjekt <-> Gruppe/Aktivitaet mit Freitext-Beschreibung (z. B. "Handball jeden Dienstag 18-20 Uhr").
-- WARUM:       UC-6 (Sportstaette = Ort fuer eine Aktivitaet) war in v3 verknuepfungstechnisch nicht abgedeckt (Gino 06.05.).
--              Eine Halle hat mehrere Sportarten, eine Sportart laeuft an mehreren Orten.
-- BEGRUENDUNG: Beschreibung gehoert in die Verknuepfung, nicht in die Stammdaten des Objekts (Adress-Design v4.1 §3); Freitext (E-002),
--              strukturierte Belegung waere ein Mini-Buchungssystem (Nicht-Ziel, v4.1 §8).
--              ON DELETE CASCADE nur auf das Objekt: Objekt loeschen raeumt seine Verknuepfungen auf; eine Gruppe mit Verknuepfungen
--              ist NICHT loeschbar (wie bei x_gruppe_mitglied, vgl. DeleteAsync-Fund).
--              Tabellenname x_objekt_gruppe statt x_objekt_ygrp (Muster x_gruppe_mitglied); Spalte ygrp_id bleibt (wie m_vereinsheim.ygrp_id,
--              y-Praefix bleibt). Naechste Alternative: x_objekt_ygrp / gruppe_id.
CREATE TABLE [yam3].[x_objekt_gruppe]
(
    [objekt_id]    INT           NOT NULL,
    [ygrp_id]      INT           NOT NULL,
    [beschreibung] NVARCHAR(200) NULL,
    [erstellt_am]  DATETIME2     NOT NULL CONSTRAINT [df_x_objekt_gruppe_erstellt] DEFAULT (SYSUTCDATETIME()),
    [erstellt_von] NVARCHAR(100) NOT NULL,
    CONSTRAINT [pk_x_objekt_gruppe]        PRIMARY KEY CLUSTERED ([objekt_id] ASC, [ygrp_id] ASC),
    CONSTRAINT [fk_x_objekt_gruppe_objekt] FOREIGN KEY ([objekt_id]) REFERENCES [yam3].[m_objekt] ([objekt_id]) ON DELETE CASCADE,
    CONSTRAINT [fk_x_objekt_gruppe_ygrp]   FOREIGN KEY ([ygrp_id])   REFERENCES [yam3].[d_gruppe] ([id])
);
```

**4. Seed (Auszug aus Scripts)**

Datei `yam2.Database/Scripts/d_land_seed.sql`

```sql
-- Seed: Minimale Länder-Daten (DE/AT/CH)
-- Idempotent: nur einfügen wenn noch nicht vorhanden
IF NOT EXISTS (SELECT 1 FROM [yam3].[d_land] WHERE [iso_code] = 'DE')
BEGIN
    INSERT INTO [yam3].[d_land] ([iso_code], [bezeichnung], [plz_regex]) VALUES
        ('DE', 'Deutschland', N'^\d{5}$'),
        ('AT', N'Österreich',  N'^\d{4}$'),
        ('CH', 'Schweiz',      N'^\d{4}$');
END
```

Datei `yam2.Database/Scripts/d_objekttyp_seed.sql`

```sql
-- d_objekttyp_seed.sql — v1.0.0 — Erstfassung (Sportstaetten SP2)
-- Seed: Objekttypen (Vereinsheim, Sportstätte, Lager, Sonstige), Adress-Design v4.1 §4.4 / §7 #6.
-- Noch NICHT an C# gekoppelt (kein Enum); bei einer Anbindung die IDs wie bei d_anrede dokumentieren (Models/MemberEnums.cs).
-- Idempotent: nur einfuegen wenn die Tabelle noch leer ist (Muster d_anr_seed.sql).
-- Kein SET IDENTITY_INSERT: objekttyp_id ist keine IDENTITY-Spalte.
-- Datei mit UTF-8-BOM, damit das "ä" in Sportstätte beim Deployment nicht als ANSI gelesen wird.
IF NOT EXISTS (SELECT 1 FROM [yam3].[d_objekttyp])
BEGIN
    INSERT INTO [yam3].[d_objekttyp] ([objekttyp_id], [bezeichnung]) VALUES
        (1, N'Vereinsheim'),
        (2, N'Sportstätte'),
        (3, N'Lager'),
        (4, N'Sonstige');
END
```

</details>

### 4.5 Namen seit v4.1 (Zuordnung alt → neu)

Das Datenbankprojekt trägt die Namen der rechten Spalte. Die linke Spalte steht nur für den Vergleich mit v4.1 und mit Ginos Feedback vom 06.05.

| Alt (v4.1 oder älter) | Neu (Projekt, `d1dfd1b`) | Grund |
|---|---|---|
| `m_gl` | `m_mitglied` | Kürzel ausschreiben (Anregung vom 20.04., §7 #1) |
| `gl_id` (in allen Tabellen) | `mitglied_id` | wie `m_mitglied` |
| `gl_adresse_id` | `mitglied_adresse_id` | wie `x_mitglied_adresse` |
| `x_gl_adresse` | `x_mitglied_adresse` | wie `m_mitglied` (Datei und Constraint-Namen: siehe §4.3) |
| `tr_x_gl_adresse_no_overlap` | `tr_x_mitglied_adresse_no_overlap` | neue Objekte folgen dem aktuellen Tabellennamen (E-011) |
| `d_ygrp` | `d_gruppe` | Kürzel ausschreiben (Welle 2) |
| `x_objekt_ygrp` | `x_objekt_gruppe` | Muster `x_gruppe_mitglied` (E-009); die Spalte `ygrp_id` bleibt |
| `m_objekt.name` | `m_objekt.bezeichnung` | wie `d_gruppe.bezeichnung` (E-009) |
| `d_sta` | `d_status` | Kürzel ausschreiben |
| `vn`, `nn`, `geb`, `tel`, `mail` | `vorname`, `nachname`, `geburtsdatum`, `telefon`, `email` | Kürzel ausschreiben (§7 #2) |
| `sepa_ref` | `sepa_referenz` | wie oben |
| `dsgvo_dat`, `dsgvo_foto` | `dsgvo_einwilligung_daten`, `dsgvo_einwilligung_foto` | wie oben |

Nur in v3 vorgesehen und durch `m_objekt` ersetzt: die Tabellen `m_vereinsheim` und `m_sportstaette` sowie die Spalte `vereinssitz_adresse_id` (siehe §9).

</details>

---

## 5. Migrations-Pfad

<details>
<summary>6 Phasen vom Ist-Zustand zum Ziel</summary>

**Ausgangslage (Stand 07.05.2026, 10 Mitglieder, eigene Stichprobe; Namen von damals in Klammern):**
- `m_mitglied.str`, `m_mitglied.plz`, `m_mitglied.ort` (damals `m_gl`) sind alle nullable — nicht jedes Mitglied hat Adressdaten
- Die neuen Tabellen (`d_land`, `d_ort`, `m_adresse`, `x_mitglied_adresse`, `d_objekttyp`, `m_objekt`, `x_objekt_gruppe`) waren damals noch **nicht** deployed; den heutigen Stand zeigt §10
- Die Gruppentabelle hat kein Adressfeld — das in v3 geplante `vereinssitz_adresse_id` ist seit v4 hinfällig

| Phase | Aktion | Breaking? | Stand |
|---|---|---|---|
| 1 | DDL aus Abschnitt 4.4 ausführen — Lookups, Adress-Kern, Vereins-Objekte, Trigger, Seed | Nein | Projekt ✓, Probelauf ✓, Team-Datenbank offen (§10) |
| 2 | Migrations-Skript: `m_mitglied`-Adressdaten in `m_adresse` + `x_mitglied_adresse` überführen — **nur Mitglieder mit mind. einem gesetzten Adressfeld** (`str` oder `plz` oder `ort` NOT NULL); leere Adressdatensätze werden übersprungen | Nein | offen |
| 3 | Repository neu: Schreibzugriff auf neue Tabellen (`Address`, `AddressValidity`, `Objekt`); Leseabfrage fällt bei leerem `x_mitglied_adresse`-Ergebnis auf alte `m_mitglied`-Spalten zurück; ViewModels und Views ergänzt | Nein | offen, wartet auf Ginos Freigabe der Konzepte |
| 4 | UI-Umstellung auf neue Struktur, alte Adress-Spalten in `m_mitglied` werden in der Anwendung nicht mehr beschrieben | Nein | offen |
| 5 | Stichtag: `DROP COLUMN` der alten Adress-Spalten in `m_mitglied` (`str`, `plz`, `ort`) über bestehendes SSDT-Projekt | Ja | offen |
| 6 | (optional) Whitespace-normalisierte Computed Columns + Unique Index — siehe §6.1 | Nein | offen (§7 #9) |

**Typ-Hinweis Phase 2:** `m_mitglied.str` ist `NVARCHAR(100) nullable`, `m_adresse.strasse` ist `NVARCHAR(100) NOT NULL`. Beim Migrieren muss ein nicht-null `str` vorhanden sein — andernfalls keinen `m_adresse`-Eintrag anlegen.

</details>

---

## 6. Optionale Erweiterungen

<details>
<summary>Whitespace-Normalisierung und m_objekt_extra</summary>

### 6.1 Whitespace-normalisierte Adress-Eindeutigkeit (Phase 6)

**Problem:** Der Standard-Index `uq_m_adresse_physisch (strasse, hausnummer, ort_id, adresszusatz)` greift bei minimalen Eingabe-Abweichungen nicht:

- `"Goethestr. 5"` vs. `"Goethestr.  5"` (zwei Spaces zwischen Bezeichner und Hausnummer-Verlängerung)
- `"Goethestr. 5"` vs. `"Goethestr. 5 "` (Trailing Space)
- `"Goethestr."` vs. `"goethestr."`

**Lösung:** Persistierte Computed Columns + zusätzlicher Unique Index auf normalisierten Werten.

```sql
ALTER TABLE [yam3].[m_adresse]
ADD strasse_norm      AS LOWER(REPLACE(LTRIM(RTRIM(strasse)),                  ' ', '')) PERSISTED,
    hausnummer_norm   AS LOWER(REPLACE(LTRIM(RTRIM(hausnummer)),               ' ', '')) PERSISTED,
    adresszusatz_norm AS LOWER(REPLACE(LTRIM(RTRIM(ISNULL(adresszusatz,''))),  ' ', '')) PERSISTED;

CREATE UNIQUE INDEX uq_m_adresse_physisch_norm
    ON [yam3].[m_adresse] (strasse_norm, hausnummer_norm, ort_id, adresszusatz_norm);
```

**Status:** 🟢 Nicht umgesetzt (geplant, Entscheidung zu §7 #9: Phase 6 nach stabiler Hauptmigration). Aktivierung erfolgt nach Phase 5, sofern erwünscht.

**Nutzen:** Real beobachtbares Problem bei manuellen Eingaben und CSV-Importen. PERSISTED Computed Columns sind in SQL Server gut indexierbar. Aufwand klein, Nutzen mittel.

**Trade-Off:** Der Original-Index `uq_m_adresse_physisch` sollte als Soft-Check belassen oder gedroppt werden — nicht beide aktiv halten, sonst doppelte Constraint-Verletzung bei trivialen Duplikaten.

### 6.2 Schlüssel-Wert-Erweiterung pro Objekt (`m_objekt_extra`)

Falls typ-spezifische Felder nötig werden (Kapazität einer Sporthalle, Hausmeister eines Vereinsheims, Lager-Inventarnummer), kann `m_objekt` ohne Schema-Änderung erweitert werden:

```sql
CREATE TABLE [yam3].[m_objekt_extra] (
    objekt_extra_id  INT IDENTITY(1,1) CONSTRAINT pk_m_objekt_extra PRIMARY KEY,
    objekt_id        INT           NOT NULL,
    schluessel       NVARCHAR(50)  NOT NULL,
    wert             NVARCHAR(500)     NULL,
    CONSTRAINT fk_m_objekt_extra_objekt
        FOREIGN KEY (objekt_id) REFERENCES [yam3].[m_objekt](objekt_id) ON DELETE CASCADE,
    CONSTRAINT uq_m_objekt_extra UNIQUE (objekt_id, schluessel)
);
```

**Status:** 🟢 Nicht umgesetzt (Entwurf). Aktivierung erst, wenn ein konkreter typ-spezifischer Erweiterungsbedarf vorliegt. Sollten echte Subtypen verlangt sein, wäre alternativ eine separate Spezialisierungstabelle pro Typ (z.B. `m_objekt_sporthalle`) sinnvoller — Entscheidung dann situationsabhängig.

</details>

---

## 7. Offene Entscheidungen

<details>
<summary>9 Punkte: 5 entschieden, 4 offen</summary>

| # | Frage | Stand |
|---|---|---|
| 1 | `m_gl` langfristig → `m_mitglied` umbenennen, mit allen FK-Spalten `gl_id → mitglied_id` | **Entschieden und im Projekt umgesetzt** (nicht in einer späteren Migration, sondern vor dem ersten Rollout; Probelauf bestanden, Team-Datenbank offen, §10) |
| 2 | ~~Bestehende `m_gl`-Kürzel (`vn`, `nn`, `tel`, `mail`, `geb`) jetzt ausschreiben oder später~~ | **Entschieden (v4.1) und umgesetzt:** Kürzel sind ausgeschrieben (Zuordnung §4.5), Ginos Anregung vom 20.04. |
| 3 | `d_ort` vorbefüllen (~8000 DE-PLZ) oder on-demand beim Speichern anlegen | **Offen.** Vorschlag unverändert: On-demand, wächst organisch |
| 4 | PLZ-Validierung per `d_land.plz_regex` in UI-Schicht aktivieren | **Offen.** Vorschlag unverändert: Ja, verhindert Müll-Daten |
| 5 | DSGVO-Anonymisierung: Felder auf NULL oder Platzhalter ("anonymisiert") | **Offen.** Vorschlag unverändert: Platzhalter, bessere Diagnose in Listen |
| 6 | `d_objekttyp`-Inhalte: reichen `Vereinsheim`, `Sportstätte`, `Lager`, `Sonstige`? Oder auch `Geschäftsstelle`, `Treffpunkt extern`? | **Offen.** Mit den vier gestartet (Seed in §4.4), weitere bei konkretem Bedarf |
| 7 | Vereinssitz: eigener `d_objekttyp`-Eintrag (z.B. `id=5 'Vereinssitz'`) **oder** Flag `ist_sitz BIT` an `m_objekt` (genau ein Eintrag pro Verein erlaubt) **oder** typ_id=1 (Vereinsheim) reicht (UC-4 wird durch Vereinsheim mit abgedeckt)? | **Entschieden und umgesetzt:** Flag `ist_sitz` an `m_objekt` mit Filter-Unique-Index `uq_m_objekt_sitz` (§4.4). Der zweite Sitz wird mit Fehler 2601 abgelehnt (Probelauf). |
| 8 | `x_objekt_gruppe.beschreibung` als Freitext oder strukturiert (Wochentag, Uhrzeit-von, Uhrzeit-bis)? | **Entschieden und umgesetzt:** Freitext (`NVARCHAR(200)`) — strukturierte Belegungsdaten gehen Richtung Mini-Buchungssystem und sind ein eigener Auftrag |
| 9 | Whitespace-Normalisierung (§6.1) als Phase 6 mit aufnehmen oder weglassen? | **Entschieden (vorläufig):** als Phase 6 nach stabiler Hauptmigration; nicht umgesetzt |

> **Erledigt mit v4** (war v3 #7): „Vereinsheim als eigene Tabelle" → ersetzt durch `m_objekt` + `d_objekttyp` (siehe §3 und §9).
>
> **Erledigt mit v4.1:** #2 (Kürzel vorgezogen ausschreiben).
>
> **Erledigt mit v4.2:** #1, #7, #8 (umgesetzt), #9 (entschieden). Die Freigabe der Konzepte durch Gino steht aus (§10).

</details>

---

## 8. Nicht-Ziele

<details>
<summary>Bewusste Scope-Grenzen</summary>

Die folgenden Themen sind nicht Teil dieses Designs und werden auf separate Anforderung umgesetzt:

- Sportstätten-Buchungen / Raumbelegung (strukturierte Termin-/Wochentags-Daten)
- Vollständige DSGVO-Compliance (Zweckbindung pro Adresse, Einwilligungsmanagement, Verarbeitungs-Einschränkung nach Art. 18)
- Adress-Zugriffs-Audit (DSGVO Art. 30)
- Polymorphe Adress-Zuordnung (für Lieferanten, Behörden, externe Partner)
- Mehrere parallele Adressen pro Mitglied (Rechnungs-, Post-, Lieferadresse)
- Vereinssitz-Historisierung (zeitliche Veränderungen des offiziellen Sitzes)
- Echte Subtypen pro `d_objekttyp` (Spezialisierungstabellen wie `m_objekt_sporthalle`, `m_objekt_vereinsheim`)

Die Struktur ist so gewählt, dass jedes dieser Themen ohne Breaking Change ergänzt werden kann.

</details>

---

## 9. Änderungsprotokoll v3 → v4 → v4.1 → v4.2

<details>
<summary>v4.1 → v4.2: Nachzug von Namen und Umsetzungsstand</summary>

| # | Änderung | Betrifft | Art |
|---|---|---|---|
| N1 | Namen an das Datenbankprojekt angepasst (`m_mitglied`, `mitglied_id`, `x_mitglied_adresse`, `d_gruppe`, `x_objekt_gruppe`, `m_objekt.bezeichnung`, `tr_x_mitglied_adresse_no_overlap`, Feldnamen in UC-11 und §3); Zuordnung alt → neu in §4.5 | alle | Namen |
| N2 | `ist_sitz` und Filter-Unique-Index `uq_m_objekt_sitz` im DDL (v4.1 V4: nur Vorschlag); §3 neue Zeile „Vereinssitz“; §7 #7 entschieden | §3, §4.1, §4.3, §4.4, §7 | umgesetzt |
| N3 | `vereinssitz_adresse_id` aus dem Datenbankprojekt entfernt (Spalte und Fremdschlüssel) | §4.1, §4.4 | umgesetzt |
| N4 | §4.4 aus den Dateien des Datenbankprojekts (Commit `d1dfd1b`) statt handgeschrieben; benannte Constraints, `sp_adresse_korrigieren` und beide Seeds sind jetzt enthalten | §4.4 | Quelle |
| N5 | V1 bis V3 (Trigger, NULL-Fall, CHECK `>`) sind im Projekt umgesetzt und mit Testfällen geprüft (Probelauf) | §4.3, §10 | Stand |
| N6 | Entscheidungen zu §7 #1, #2, #7, #8, #9 eingetragen; #3 bis #6 bleiben offen | §7 | Stand |
| N7 | Neu §10 „Stand der Umsetzung“; Phasentabelle in §5 um Spalte „Stand“ ergänzt; §3 zählt 18 statt 16 Entscheidungen | §3, §5, §10 | Stand |

</details>

<details>
<summary>v4 → v4.1: 5 Korrekturen aus eigener Prüfung (30.09.2026)</summary>

| # | Änderung | Betrifft | Schwere |
|---|---|---|---|
| V1 | `tr_x_gl_adresse_no_overlap` (heute `tr_x_mitglied_adresse_no_overlap`): Bedingung von `<=` / `>=` auf `<` / `<` umgestellt (`a.von < b.bis AND b.von < a.bis`). v4 behandelte `gueltig_bis` als eingeschlossen, §3 legt aber `[von, bis)` fest — ein normaler Umzug (alte Zeile `bis` = neue Zeile `von`) wäre als Überlappung abgelehnt worden und hätte UC-2/UC-7 blockiert | §4.3, §4.4 | 🔴 Fehler |
| V2 | `tr_m_adresse_immutable`: `IF CONTEXT_INFO() IS NULL OR CONTEXT_INFO() <> …`. Ohne den NULL-Zweig ergibt der Vergleich UNKNOWN, das `IF` greift nicht und das UPDATE läuft durch — die Unveränderlichkeit wirkte gerade im Normalfall nicht | §4.3, §4.4 | 🔴 Fehler |
| V3 | `ck_x_gl_adresse_zeitraum`: `gueltig_bis > gueltig_von` statt `>=`. Bei halb-offenem Intervall wäre `von = bis` ein leerer Zeitraum | §4.4 | 🟡 Präzisierung |
| V4 | `ist_sitz` (Vorschlag zu §7 #7) stand nur in der Entscheidungstabelle, nicht im DDL — in v4.1 als „abhängig von #7“ gekennzeichnet; seit v4.2 umgesetzt (N2) | §4.1, §4.4, §7 | 🟢 Klarstellung |
| V5 | §7 #2 (Kürzel jetzt oder später) als entschieden markiert: vorgezogene Umbenennung, unabhängig von #1. Seit v4.2 zeigen UC-11 und §3 die neuen Feldnamen (N1) | §2, §7 | 🟡 Folge aus eigener Entscheidung |

**Hinweis zu V2:** Der Immutable-Trigger war bereits mit v3 in Planung. Das Datenbankprojekt enthält ihn mit dem NULL-Zweig (§4.4).

</details>

<details>
<summary>v3 → v4: 5 Änderungen aus Gino-Feedback vom 06.05.2026</summary>

| # | Änderung | Betrifft | Schwere |
|---|---|---|---|
| 1 | `m_vereinsheim` und `m_sportstaette` zusammengeführt zu `m_objekt` + `d_objekttyp` | §3, §4.1, §4.2, §4.4 | 🔴 Strukturell |
| 2 | Junction `x_objekt_ygrp` (heute `x_objekt_gruppe`) ergänzt — verknüpft Sportstätte (oder anderes Objekt) mit Gruppe/Aktivität, Beschreibungs-Spalte für Kontext ("Handball Dienstag 18-20"); UC-6 war in v3 modelltechnisch nicht abgedeckt | §3, §4.1, §4.2, §4.4 | 🔴 Strukturell |
| 3 | Trigger `tr_x_gl_adresse_no_overlap` (heute `tr_x_mitglied_adresse_no_overlap`) ergänzt — verhindert Überlappungen zweier geschlossener Gültigkeits-Intervalle für dieselbe `gl_id` (heute `mitglied_id`), die der Filter-Unique-Index nicht abdeckt | §3, §4.3, §4.4 | 🔴 Strukturell |
| 4 | Whitespace-Normalisierung als optionale Phase 6 aufgenommen — Computed Columns + zusätzlicher Unique Index | §5 (Phase 6), §6.1, §7 #9 | 🟢 Optional |
| 5 | `vereinssitz_adresse_id` aus v3 entfernt — Vereinssitz wird über `m_objekt` modelliert (§7 #7 zur konkreten Variante) | §4.1, §4.4, §7 | 🟡 Folge aus #1 |

</details>

---

## 10. Stand der Umsetzung

<details>
<summary>Je Punkt aus Ihrem Feedback: Projekt, Probelauf, Team-Datenbank</summary>

Spalten: **Projekt** = im Datenbankprojekt (Stand `d1dfd1b`) · **Probelauf** = auf einer Probe-Datenbank veröffentlicht und geprüft (nicht auf der Team-Datenbank) · **Team-Datenbank** = auf der produktiven Datenbank. ✓ erreicht · – noch nicht · ? nicht belegt. Die Belege (Beleg P5-n) liegen intern vor und nennen je Aussage Quelle und Fundstelle.

| Punkt aus Ginos Feedback | Umsetzung | Projekt | Probelauf | Team-Datenbank | Beleg |
|---|---|---|---|---|---|
| Kürzel ausschreiben (20.04., 23.04.) | 49 Umbenennungen, u. a. `m_mitglied`, `d_gruppe`, `x_mitglied_adresse` (§4.5) | ✓ | ✓ (Rückweg getestet) | – (wartet auf Ginos Freigabe, dann Rollout) | P5-1 |
| Vereinssitz, Vereinsheim, Sportstätte zusammenführen und verknüpfen (UC-4 bis UC-6; 06.05.) | `d_objekttyp`, `m_objekt` mit `ist_sitz`, `x_objekt_gruppe` | ✓ | ✓ (Sitz: erster OK, zweiter Fehler 2601; Verknüpfung getestet) | – (nach dem Rollout der Umbenennung; Reihenfolge entschieden) | P5-2 |
| Intervall-Überlappung im DDL schützen (06.05.) | Trigger `tr_x_mitglied_adresse_no_overlap`, CHECK `ck_x_gl_adresse_zeitraum` mit `>` | ✓ | ✓ (10 von 10 Testfällen: Umzug erlaubt, Überlappungen und leerer Zeitraum abgelehnt) | – (zusammen mit den Sportstätten) | P5-3 |
| Immutable `m_adresse`, Korrektur nur über SP (V2) | `tr_m_adresse_immutable` mit NULL-Zweig, `sp_adresse_korrigieren` | ✓ | ? (kein eigener Probelauf-Beleg für den Trigger) | – (die Prozedur kommt laut Plan mit dem Rollout; der Trigger: ?) | P5-4 |
| `vereinssitz_adresse_id` entfällt (v4) | Spalte und Fremdschlüssel aus dem Projekt entfernt; Spalte war leer | ✓ | ✓ | – (eigener kleiner Rollout, Sperre gegen Datenverlust einmalig aus) | P5-5 |
| Adress-Kern: `d_land`, `d_ort`, `m_adresse`, `x_mitglied_adresse` | DDL in §4.4 | ✓ | ✓ (durch die Testfälle der Intervall-Prüfung) | ? (Abgleich mit dem Inventar der Team-Datenbank steht aus) | P5-6 |
| Adress-Umsetzung Phasen 2 bis 5 (§5): Daten übernehmen, Repository, UI, Altspalten | – | – | – | – (wartet auf Ginos Freigabe der Konzepte) | P5-7 |
| Whitespace-Normalisierung (§6.1) | – | – | – | – (Phase 6, vorläufig entschieden) | P5-8 |

Offen: Ginos Freigabe der Adress-Konzepte (v4.2) steht aus; erst danach folgen die Anwendungsteile (Repository, Oberfläche) der Phasen 3 bis 5. Offene Fragen zu den Punkten #3 bis #6 in §7.

</details>
