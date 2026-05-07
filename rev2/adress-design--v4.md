# yam2 — Adress-Infrastruktur

**Stand:** 07.05.2026
**Version:** 4 — konsolidiert aus v3 (21.04.2026) + Gino-Feedback vom 06.05.2026
**Autor:** Ovaya

Beschreibt das Design der Adress-Infrastruktur für yam2. Vorgaben aus dem Teams-Gespräch:
- vom 20.04.2026 und
- dem Folge-Gespräch vom 06.05.2026.

Reihenfolge: Anwendungsfälle → Logik → DB-Design → Umsetzungsplan. 

**Was ist neu in v4?**  -  Details: Abschnitt 10.
- Vereinsheim und Sportstätte sind in eine gemeinsame Tabelle `m_objekt` mit Typ-Lookup `d_objekttyp` zusammengeführt.
- Sportstätten sind über die Junction-Tabelle `x_objekt_ygrp` an Gruppen/Aktivitäten verknüpft (UC-6 vorher modelltechnisch nicht abgedeckt).
- Intervall-Überlappungen in `x_gl_adresse` werden zusätzlich per Trigger verhindert.
- Whitespace-Normalisierung der Adress-Kerndaten ist als optionale Erweiterung vorgesehen.

---

## 📋 Inhalt

1. [Kontext & Auftrag](#1-kontext--auftrag)
2. [Anwendungsfälle](#2-anwendungsfälle)
3. [Logik-Entscheidungen](#3-logik-entscheidungen)
4. [DB-Design](#4-db-design)
5. [Migrations-Pfad](#5-migrations-pfad)
6. [Voraussetzung: DB-Projekt](#6-voraussetzung-db-projekt)
7. [Optionale Erweiterungen](#7-optionale-erweiterungen)
8. [Offene Entscheidungen](#8-offene-entscheidungen)
9. [Nicht-Ziele](#9-nicht-ziele)
10. [Änderungsprotokoll v3 → v4](#10-änderungsprotokoll-v3--v4)

---

## 1. Kontext & Auftrag

<details>
<summary>Anforderungen aus den Teams-Gesprächen</summary>

Vorgaben aus dem Gespräch vom **20.04.2026**:

- `d_ygrp` soll die Möglichkeit haben, ein Vereinsheim zu definieren
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

Das Dokument folgt dieser Reihenfolge. Abschnitt 2 sind die Functional Specs (Anwendungsfälle), Abschnitt 3 die Technical Specs (Logik), Abschnitt 4 das DB-Design.

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
| UC-11 | DSGVO-Löschung | Personendaten in `m_gl` anonymisieren: `vn`, `nn`, `geb`, `mail`, `tel`, `iban`, `bic`, `sepa_ref`, `sepa_datum` → Platzhalter; `dsgvo_dat`, `dsgvo_foto` → 0. `m_adresse` bleibt unberührt (gebäudebezogen) |
| UC-12 | Mahnbrief historisch | Adresse zum Fälligkeitsdatum verwenden |
| UC-13 | Austritt | Adress-Zuordnung bleibt aktiv; Mitgliedschafts-Status wird über bestehendes `d_sta` abgebildet. Datenschutz-Einschränkungen (Art. 18 DSGVO) sind nicht Teil dieses Designs |

</details>

---

## 3. Logik-Entscheidungen

<details>
<summary>16 Entscheidungen mit Begründung</summary>

| Thema | Entscheidung | Begründung |
|---|---|---|
| Mehrere Adressen parallel | Nein, genau eine aktive pro Mitglied | Komplexität ohne Vereins-Nutzen |
| Historisierung-Ort | Separate Zuordnungstabelle `x_gl_adresse` | Mitglied-Stammdaten bleiben sauber |
| Adress-Datensatz | Immutable per Trigger | Historie sonst inkonsistent |
| Tippfehler-Korrektur | Eigene SP `sp_adresse_korrigieren` | Einziger legitimer Änderungs-Pfad |
| Umzug vs. Korrektur | Zwei getrennte Fach-Operationen | Semantische Klarheit |
| Haushalt-Konzept | Implizit über geteilte `adresse_id` | Kein eigener Typ nötig |
| Haushalts-Umzug | Eigene Operation `MoveHousehold` | Atomar für alle betroffenen Mitglieder |
| Austritt | Mitgliedschafts-Status über bestehendes `d_sta`, Adress-Zuordnung bleibt aktiv | Statusmechanismus ist bereits implementiert; DSGVO-Einschränkung der Verarbeitung ist separates Modul |
| DSGVO-Löschung | Felder `vn`, `nn`, `geb`, `mail`, `tel`, `iban`, `bic`, `sepa_ref`, `sepa_datum` → Platzhalter; `dsgvo_dat`/`dsgvo_foto` → 0; `m_adresse` bleibt | AO §147 (10 Jahre Beitragsdaten); Adresse ist gebäudebezogen; Feldnamen entsprechen Live-DB-Stand (Umbenennung noch pending) |
| Gültigkeits-Intervall | Halb-offen `[gueltig_von, gueltig_bis)` | `gueltig_bis` ist erster Tag ohne Gültigkeit — verhindert Grenzfall-Duplikate bei Abfragen zum Stichtag |
| **Intervall-Überlappung** | **Doppelte Absicherung: Filter-Unique-Index + AFTER-Trigger** | UNIQUE-Index deckt nur den NULL-Fall (eine offene Gültigkeit) ab. Zwei geschlossene Intervalle können sich trotzdem überlappen — Trigger fängt das ab. Anwendungslogik allein reicht nicht (Direkt-SQL umgeht sie). |
| Land-Support | `d_land` Lookup mit PLZ-Regex | Internationale Mitglieder möglich |
| PLZ-Feld | `VARCHAR(10)` | DE 5 / AT 4 / CH 4 / GB bis 8 alphanum. |
| Hausnummer | NULL zulässig mit CHECK-Constraint | Postfach, "an der alten Mühle" |
| **Vereinsobjekte** | **Gemeinsame Basis `m_objekt` mit Typ-Lookup `d_objekttyp` (Vereinsheim, Sportstätte, Lager, Sonstige)** | Vereinsheim und Sportstätte teilen Name, Adresse, Audit-Felder, Aktiv-Flag. Vorab-Trennung würde einheitliche Abfragen ("alle Vereinsobjekte mit Adresse") behindern. Spezialisierung über `m_objekt_extra` oder echte Subtypen lässt sich nachrüsten — zwei Tabellen wieder zu mergen ist deutlich teurer. |
| **Sportstätten-Verknüpfung** | **N:M-Junction `x_objekt_ygrp` mit Beschreibungs-Spalte** | Eine Halle beherbergt mehrere Sportarten, eine Sportart läuft an mehreren Orten. Beschreibung ("Dienstag 18-20") gehört in die Verknüpfung, nicht in die Stammdaten der Sportstätte. |
| Sportstätten-Buchung | Nicht in diesem Design | Eigenes Modul, nicht beauftragt |

</details>

---

## 4. DB-Design

<details>
<summary>Tabellen, Beziehungen, vollständige DDL</summary>

### 4.1 Tabellen-Übersicht

| Tabelle | Rolle | Status |
|---|---|---|
| `d_land` | Lookup: Länder + PLZ-Regex | NEU |
| `d_ort` | Lookup: PLZ/Ort länderabhängig | NEU |
| `m_adresse` | Adress-Stammdaten (immutable) | NEU |
| `x_gl_adresse` | Zuordnung Mitglied ↔ Adresse + Historie | NEU |
| `d_objekttyp` | Lookup: Typ eines Vereinsobjekts | NEU |
| `m_objekt` | Vereinsobjekte (Vereinsheim, Sportstätte, …) | NEU |
| `x_objekt_ygrp` | Junction Objekt ↔ Gruppe + Beschreibung | NEU |
| `m_objekt_extra` | Schlüssel-Wert-Erweiterung pro Objekt | OPTIONAL — Phase 1 nicht enthalten |

> Hinweis: Die in v3 vorgesehene Spalte `d_ygrp.vereinssitz_adresse_id` entfällt. Vereinssitz wird über `m_objekt` modelliert (siehe offene Entscheidung 10 zur konkreten Variante).

### 4.2 Beziehungen

```
d_land ◄── d_ort ◄── m_adresse ◄── x_gl_adresse ──► m_gl
                          ▲
                          │
d_objekttyp ◄── m_objekt ─┘
                  ▲
                  │
                  └── x_objekt_ygrp ──► d_ygrp
```

### 4.3 Zentrale Konstrukte

- Filter-Unique-Index `uq_x_gl_adresse_aktiv WHERE gueltig_bis IS NULL` — max. eine offene Gültigkeit pro Mitglied
- **Trigger `tr_x_gl_adresse_no_overlap` (NEU v4)** — verhindert sich überlappende geschlossene Intervalle
- Immutable-Trigger `tr_m_adresse_immutable` — UPDATE auf `m_adresse` nur via SP mit `CONTEXT_INFO`
- CHECK-Constraint `ck_m_adresse_mindestangabe` — Hausnummer oder Adresszusatz gesetzt
- Dedupe-Index `uq_m_adresse_physisch` — identische Adressen nur einmal

### 4.4 Vollständige DDL

<details>
<summary>SQL-Skript einblenden</summary>

```sql
-- ─── 1. LOOKUPS ─────────────────────────────────────────────────────

CREATE TABLE [yam3].[d_land] (
    land_id       INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_d_land PRIMARY KEY,
    iso_code      CHAR(2)       NOT NULL,
    bezeichnung   NVARCHAR(100) NOT NULL,
    plz_regex     NVARCHAR(100)     NULL,
    CONSTRAINT uq_d_land_iso UNIQUE (iso_code)
);

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

CREATE TABLE [yam3].[d_objekttyp] (
    objekttyp_id  INT          NOT NULL CONSTRAINT pk_d_objekttyp PRIMARY KEY,
    bezeichnung   NVARCHAR(50) NOT NULL,
    CONSTRAINT uq_d_objekttyp_bezeichnung UNIQUE (bezeichnung)
);
GO


-- ─── 2. ADRESS-KERN ─────────────────────────────────────────────────

CREATE TABLE [yam3].[m_adresse] (
    adresse_id    INT            NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_adresse PRIMARY KEY,
    strasse       NVARCHAR(100)  NOT NULL,
    hausnummer    NVARCHAR(10)       NULL,
    adresszusatz  NVARCHAR(100)  NOT NULL CONSTRAINT df_m_adresse_zusatz DEFAULT '',
    ort_id        INT            NOT NULL CONSTRAINT fk_m_adresse_ort REFERENCES [yam3].[d_ort](ort_id),
    erstellt_am   DATETIME2      NOT NULL CONSTRAINT df_m_adresse_erstellt DEFAULT SYSUTCDATETIME(),
    erstellt_von  NVARCHAR(100)  NOT NULL,
    CONSTRAINT ck_m_adresse_mindestangabe
        CHECK (hausnummer IS NOT NULL OR LEN(adresszusatz) > 0)
);

CREATE UNIQUE INDEX uq_m_adresse_physisch
    ON [yam3].[m_adresse] (strasse, hausnummer, ort_id, adresszusatz);
GO

CREATE TRIGGER [yam3].[tr_m_adresse_immutable]
ON [yam3].[m_adresse]
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
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


CREATE TABLE [yam3].[x_gl_adresse] (
    gl_adresse_id    INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_x_gl_adresse PRIMARY KEY,
    gl_id            INT           NOT NULL CONSTRAINT fk_x_gl_adresse_gl      REFERENCES [yam3].[m_gl](id),
    adresse_id       INT           NOT NULL CONSTRAINT fk_x_gl_adresse_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    gueltig_von      DATE          NOT NULL,
    gueltig_bis      DATE              NULL,
    geaendert_am     DATETIME2     NOT NULL CONSTRAINT df_x_gl_adresse_geaendert DEFAULT SYSUTCDATETIME(),
    geaendert_von    NVARCHAR(100) NOT NULL,
    CONSTRAINT ck_x_gl_adresse_zeitraum
        CHECK (gueltig_bis IS NULL OR gueltig_bis >= gueltig_von)
);

CREATE UNIQUE INDEX uq_x_gl_adresse_aktiv
    ON [yam3].[x_gl_adresse] (gl_id)
    WHERE gueltig_bis IS NULL;

CREATE INDEX ix_x_gl_adresse_zeitraum
    ON [yam3].[x_gl_adresse] (gl_id, gueltig_von, gueltig_bis);
GO

CREATE OR ALTER TRIGGER [yam3].[tr_x_gl_adresse_no_overlap]
ON [yam3].[x_gl_adresse]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM [yam3].[x_gl_adresse] a
        JOIN [yam3].[x_gl_adresse] b
          ON a.gl_id          =  b.gl_id
         AND a.gl_adresse_id  <  b.gl_adresse_id                          -- jedes Paar nur einmal
         AND a.gueltig_von                       <= ISNULL(b.gueltig_bis, '9999-12-31')
         AND ISNULL(a.gueltig_bis, '9999-12-31') >= b.gueltig_von
        WHERE a.gl_id IN (SELECT gl_id FROM inserted)
    )
    BEGIN
        RAISERROR('Adress-Gültigkeitsintervalle überlappen sich für dieselbe gl_id.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
GO


-- ─── 3. VEREINS-OBJEKTE ─────────────────────────────────────────────

CREATE TABLE [yam3].[m_objekt] (
    objekt_id        INT            NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_objekt PRIMARY KEY,
    name             NVARCHAR(100)  NOT NULL,
    typ_id           INT            NOT NULL CONSTRAINT fk_m_objekt_typ     REFERENCES [yam3].[d_objekttyp](objekttyp_id),
    adresse_id       INT            NOT NULL CONSTRAINT fk_m_objekt_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    ist_vereinseigen BIT            NOT NULL CONSTRAINT df_m_objekt_eigen     DEFAULT 0,
    beschreibung     NVARCHAR(500)      NULL,
    aktiv            BIT            NOT NULL CONSTRAINT df_m_objekt_aktiv     DEFAULT 1,
    erstellt_am      DATETIME2      NOT NULL CONSTRAINT df_m_objekt_erstellt  DEFAULT SYSUTCDATETIME(),
    erstellt_von     NVARCHAR(100)  NOT NULL,
    geaendert_am     DATETIME2          NULL,
    geaendert_von    NVARCHAR(100)      NULL
);
GO

CREATE TABLE [yam3].[x_objekt_ygrp] (
    objekt_id     INT            NOT NULL,
    ygrp_id       INT            NOT NULL,
    beschreibung  NVARCHAR(200)      NULL,                                  -- z.B. "Handball jeden Dienstag 18-20 Uhr"
    erstellt_am   DATETIME2      NOT NULL CONSTRAINT df_x_objekt_ygrp_erstellt DEFAULT SYSUTCDATETIME(),
    erstellt_von  NVARCHAR(100)  NOT NULL,
    CONSTRAINT pk_x_objekt_ygrp PRIMARY KEY (objekt_id, ygrp_id),
    CONSTRAINT fk_x_objekt_ygrp_objekt
        FOREIGN KEY (objekt_id) REFERENCES [yam3].[m_objekt](objekt_id) ON DELETE CASCADE,
    CONSTRAINT fk_x_objekt_ygrp_ygrp
        FOREIGN KEY (ygrp_id)   REFERENCES [yam3].[d_ygrp](id)
);
GO


-- ─── 4. SEED: MINIMAL ───────────────────────────────────────────────

INSERT INTO [yam3].[d_land] (iso_code, bezeichnung, plz_regex) VALUES
    ('DE', 'Deutschland', '^\d{5}$'),
    ('AT', 'Österreich',  '^\d{4}$'),
    ('CH', 'Schweiz',     '^\d{4}$');

INSERT INTO [yam3].[d_objekttyp] (objekttyp_id, bezeichnung) VALUES
    (1, 'Vereinsheim'),
    (2, 'Sportstätte'),
    (3, 'Lager'),
    (4, 'Sonstige');
GO
```

</details>

</details>

---

## 5. Migrations-Pfad

<details>
<summary>6 Phasen vom Ist-Zustand zum Ziel</summary>

**Live-DB-Status (Stand 2026-05-07, 10 Mitglieder, eigene Stichprobe):**
- `m_gl.str`, `m_gl.plz`, `m_gl.ort` sind alle nullable — nicht jedes Mitglied hat Adressdaten
- Sämtliche neuen Tabellen (`d_land`, `d_ort`, `m_adresse`, `x_gl_adresse`, `d_objekttyp`, `m_objekt`, `x_objekt_ygrp`) sind noch **nicht** deployed
- `d_ygrp` hat kein Adressfeld — der zuvor in v3 geplante `vereinssitz_adresse_id` ist mit v4 hinfällig

| Phase | Aktion | Breaking? |
|---|---|---|
| 1 | DDL aus Abschnitt 4.4 ausführen — Lookups, Adress-Kern, Vereins-Objekte, Trigger, Seed | Nein |
| 2 | Migrations-Skript: `m_gl`-Adressdaten in `m_adresse` + `x_gl_adresse` überführen — **nur Mitglieder mit mind. einem gesetzten Adressfeld** (`str` oder `plz` oder `ort` NOT NULL); leere Adressdatensätze werden übersprungen | Nein |
| 3 | Repository neu: Schreibzugriff auf neue Tabellen (`Address`, `AddressValidity`, `Objekt`); Leseabfrage fällt bei leerem `x_gl_adresse`-Ergebnis auf alte `m_gl`-Spalten zurück; ViewModels und Views ergänzt | Nein |
| 4 | UI-Umstellung auf neue Struktur, alte Adress-Spalten in `m_gl` werden in der Anwendung nicht mehr beschrieben | Nein |
| 5 | Stichtag: `DROP COLUMN` der alten Adress-Spalten in `m_gl` (`str`, `plz`, `ort`) via SSDT | Ja — nur mit DB-Projekt machbar |
| 6 | (optional) Whitespace-normalisierte Computed Columns + Unique Index — siehe Abschnitt 7 | Nein |

**Typ-Hinweis Phase 2:** `m_gl.str` ist `NVARCHAR(100) nullable`, `m_adresse.strasse` ist `NVARCHAR(100) NOT NULL`. Beim Migrieren muss ein nicht-null `str` vorhanden sein — andernfalls keinen `m_adresse`-Eintrag anlegen.

Die Breaking-Change-Phase 5 setzt ein eingeführtes DB-Projekt voraus (siehe Abschnitt 6).

</details>

---

## 6. Voraussetzung: DB-Projekt

<details>
<summary>SSDT-Einführung, Struktur, Workflow, ca. 5 Stunden</summary>

Im Teams-Gespräch wurde angemerkt, dass ein DB-Projekt noch fehlt und Schema-Drift bereits sichtbar ist. Das Design der Adress-Infrastruktur bringt sieben neue Tabellen (acht inkl. optional `m_objekt_extra`) sowie zwei neue Trigger — ohne versioniertes Schema vergrößert sich die Drift weiter. Die Einführung eines SQL Server Database Projects (SSDT) wird daher vor oder parallel zur Umsetzung empfohlen.

### 6.1 Struktur

```
yam2.sln
├── yam2/                         # WPF-App (bestehend)
└── yam2.Database/                # NEU: SSDT-Projekt
    ├── yam3/
    │   ├── Tables/               # m_gl.sql, m_adresse.sql, x_gl_adresse.sql, m_objekt.sql, …
    │   ├── Views/
    │   ├── StoredProcedures/
    │   ├── Triggers/             # tr_f_ist_auto_close.sql, tr_m_adresse_immutable.sql,
    │   │                         # tr_x_gl_adresse_no_overlap.sql
    │   └── Security/
    ├── Scripts/
    │   ├── PreDeployment.sql
    │   └── PostDeployment.sql    # Seed-Daten (Lookups, RBAC)
    └── yam2.Database.sqlproj
```

### 6.2 Einführungs-Schritte

| # | Schritt | Aufwand |
|---|---|---|
| 1 | SSDT-Projekt in Solution anlegen | 10 min |
| 2 | Schema-Import aus `SauerSQL2.ovaya_test.yam3` (Schema Compare / Import Wizard) | 30 min |
| 3 | Build — DACPAC erzeugen, Validierungsfehler beheben | 1 h |
| 4 | Post-Deployment-Skript für Seed-Daten (`d_perm`, `d_role`, `d_anr`, `d_sta`, `d_objekttyp`, …) | 1 h |
| 5 | Schema-Compare gegen Live-DB, Drift dokumentieren und synchronisieren | 2 h |
| 6 | Git-Commit — ab hier alle Schema-Änderungen nur über Projekt | — |

Gesamt: ca. 5 Stunden initial.

### 6.3 Workflow ab Einführung

Neue Tabelle oder Schema-Änderung:
1. SQL-Datei im DB-Projekt anlegen oder ändern
2. Build — DACPAC wird erzeugt
3. Git-Commit
4. Deployment via Schema Compare oder `sqlpackage.exe /Publish`
5. Rollback über vorherigen DACPAC-Stand

Breaking Changes (Umbenennung, DROP COLUMN) werden über Pre- und Post-Deployment-Skripte mit Datenmigration abgesichert.

</details>

---

## 7. Optionale Erweiterungen

<details>
<summary>Whitespace-Normalisierung und m_objekt_extra</summary>

### 7.1 Whitespace-normalisierte Adress-Eindeutigkeit (Phase 6)

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

**Status:** 🟢 Nicht in Phase 1 enthalten. Aktivierung erfolgt nach Phase 5, sofern erwünscht.

**Nutzen:** Real beobachtbares Problem bei manuellen Eingaben und CSV-Importen. PERSISTED Computed Columns sind in SQL Server gut indexierbar. Aufwand klein, Nutzen mittel.

**Trade-Off:** Der Original-Index `uq_m_adresse_physisch` sollte als Soft-Check belassen oder gedroppt werden — nicht beide aktiv halten, sonst doppelte Constraint-Verletzung bei trivialen Duplikaten.

### 7.2 Schlüssel-Wert-Erweiterung pro Objekt (`m_objekt_extra`)

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

**Status:** 🟢 Nicht in Phase 1 enthalten. Aktivierung erst, wenn ein konkreter typ-spezifischer Erweiterungsbedarf vorliegt. Sollten echte Subtypen verlangt sein, wäre alternativ eine separate Spezialisierungstabelle pro Typ (z.B. `m_objekt_sporthalle`) sinnvoller — Entscheidung dann situationsabhängig.

</details>

---

## 8. Offene Entscheidungen

<details>
<summary>10 Punkte zur Freigabe</summary>

| # | Frage | Vorschlag |
|---|---|---|
| 1 | `m_gl` langfristig → `m_mitglied` umbenennen, mit allen FK-Spalten `gl_id → mitglied_id` | Ja, in separater Migration nach Adress-Abschluss |
| 2 | Bestehende `m_gl`-Kürzel (`vn`, `nn`, `tel`, `mail`, `geb`) jetzt ausschreiben oder später | Später, gemeinsam mit Punkt 1 |
| 3 | `d_ort` vorbefüllen (~8000 DE-PLZ) oder on-demand beim Speichern anlegen | On-demand, wächst organisch |
| 4 | PLZ-Validierung per `d_land.plz_regex` in UI-Schicht aktivieren | Ja, verhindert Müll-Daten |
| 5 | DB-Projekt vor der Adress-Implementierung aufsetzen | Ja |
| 6 | DSGVO-Anonymisierung: Felder auf NULL oder Platzhalter ("anonymisiert") | Platzhalter, bessere Diagnose in Listen |
| 7 | `d_objekttyp`-Inhalte: reichen `Vereinsheim`, `Sportstätte`, `Lager`, `Sonstige`? Oder auch `Geschäftsstelle`, `Treffpunkt extern`? | Mit den vier starten, weitere bei konkretem Bedarf ergänzen |
| 8 | Vereinssitz: eigener `d_objekttyp`-Eintrag (z.B. `id=5 'Vereinssitz'`) **oder** Flag `ist_sitz BIT` an `m_objekt` (genau ein Eintrag pro Verein erlaubt) **oder** typ_id=1 (Vereinsheim) reicht (UC-4 wird durch Vereinsheim mit abgedeckt)? | Flag `ist_sitz` an `m_objekt` mit Filter-Unique-Index `WHERE ist_sitz = 1` — sauber semantisch, ein Sitz pro Verein erzwingbar |
| 9 | `x_objekt_ygrp.beschreibung` als Freitext oder strukturiert (Wochentag, Uhrzeit-von, Uhrzeit-bis)? | Freitext für jetzt — strukturierte Belegungsdaten gehen Richtung Mini-Buchungssystem und sind ein eigener Auftrag |
| 10 | Whitespace-Normalisierung (Abschnitt 7.1) als Phase 6 mit aufnehmen oder weglassen? | Aufnehmen, sobald die Hauptmigration stabil ist |

> **Erledigt mit v4** (war v3 #7): „Vereinsheim als eigene Tabelle" → ersetzt durch `m_objekt` + `d_objekttyp` (siehe §3 und §10).

</details>

---

## 9. Nicht-Ziele

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

## 10. Änderungsprotokoll v3 → v4

<details>
<summary>5 Änderungen aus Gino-Feedback vom 06.05.2026</summary>

| # | Änderung | Betrifft | Schwere |
|---|---|---|---|
| 1 | `m_vereinsheim` und `m_sportstaette` zusammengeführt zu `m_objekt` + `d_objekttyp` | §3, §4.1, §4.2, §4.4, §6.1 (SSDT-Struktur) | 🔴 Strukturell |
| 2 | Junction `x_objekt_ygrp` ergänzt — verknüpft Sportstätte (oder anderes Objekt) mit Gruppe/Aktivität, Beschreibungs-Spalte für Kontext ("Handball Dienstag 18-20"); UC-6 war in v3 modelltechnisch nicht abgedeckt | §3, §4.1, §4.2, §4.4 | 🔴 Strukturell |
| 3 | Trigger `tr_x_gl_adresse_no_overlap` ergänzt — verhindert Überlappungen zweier geschlossener Gültigkeits-Intervalle für dieselbe `gl_id`, die der Filter-Unique-Index nicht abdeckt | §3 (Logik-Eintrag „Intervall-Überlappung"), §4.3, §4.4 | 🔴 Strukturell |
| 4 | Whitespace-Normalisierung als optionale Phase 6 aufgenommen — Computed Columns + zusätzlicher Unique Index | §3 (entfällt — siehe `Vereinsobjekte`-Eintrag), §5 (Phase 6), §7.1 | 🟢 Optional |
| 5 | `d_ygrp.vereinssitz_adresse_id` aus v3 entfernt — Vereinssitz wird über `m_objekt` modelliert (offene Entscheidung 8 zur konkreten Variante) | §4.1, §4.4 (kein `ALTER TABLE d_ygrp` mehr), §8 | 🟡 Folge aus #1 |

**Zusatzkonsolidierungen ohne neue Inhalte:**

- Tabellen-Übersicht §4.1 zeigt jetzt eine Status-Spalte (NEU / OPTIONAL)
- Trigger-Einträge in §6.1 SSDT-Struktur ergänzt (`tr_m_adresse_immutable`, `tr_x_gl_adresse_no_overlap`)
- Migrations-Pfad §5 hat sechs statt fünf Phasen (Phase 6 = Whitespace-Norm)
- Offene Entscheidungen §8: vier neue Punkte (7–10) ergänzt; v3 #7 als „erledigt mit v4" gekennzeichnet
- Nicht-Ziele §9 erweitert um „echte Subtypen pro `d_objekttyp`"

</details>
