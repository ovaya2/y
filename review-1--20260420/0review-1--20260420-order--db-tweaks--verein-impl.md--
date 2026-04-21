# yam2 — Adress-Infrastruktur

**Stand:** 20.04.2026
**Autor:** Ovaya

Das Dokument beschreibt das Design der Adress-Infrastruktur für yam2 entsprechend der Vorgaben aus dem Teams-Gespräch vom 20.04.2026. Aufbau in der klassischen Reihenfolge: Anwendungsfälle → Logik → DB-Design → Umsetzungsplan. Die Abschnitte sind einklappbar; zur Übersicht das Inhaltsverzeichnis nutzen und gezielt öffnen.

---

## 📋 Inhalt

1. [Kontext & Auftrag](#1-kontext--auftrag)
2. [Anwendungsfälle](#2-anwendungsfälle)
3. [Logik-Entscheidungen](#3-logik-entscheidungen)
4. [DB-Design](#4-db-design)
5. [Migrations-Pfad](#5-migrations-pfad)
6. [Voraussetzung: DB-Projekt](#6-voraussetzung-db-projekt)
7. [Offene Entscheidungen](#7-offene-entscheidungen)
8. [Nicht-Ziele](#8-nicht-ziele)

---

## 1. Kontext & Auftrag

<details>
<summary>Anforderungen aus dem Teams-Gespräch</summary>

Vorgaben aus dem Gespräch vom 20.04.2026:

- `d_ygrp` soll die Möglichkeit haben, ein Vereinsheim zu definieren
- Der Verein braucht einen Sitz
- Sportstätten sind Orte, an denen bestimmte Tätigkeiten stattfinden (Beispiel: Handball, Turnen in Sporthalle Beispielstraße 3)
- Anwendungsfälle und Logik zusammenschreiben — insbesondere Historisierung und mehrere Mitglieder an gleicher Adresse
- Erst Design, dann Implementierung
- Reihenfolge: Kundenanforderung → Functional Specs → Technical Specs → DB-Design → Implementierung

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
| UC-11 | DSGVO-Löschung | Personendaten anonymisieren, Adresse selbst bleibt |
| UC-12 | Mahnbrief historisch | Adresse zum Fälligkeitsdatum verwenden |
| UC-13 | Austritt | Adresse bleibt aktiv — Austritt ≠ Umzug |

</details>

---

## 3. Logik-Entscheidungen

<details>
<summary>14 Entscheidungen mit Begründung</summary>

| Thema | Entscheidung | Begründung |
|---|---|---|
| Mehrere Adressen parallel | Nein, genau eine aktive pro Mitglied | Komplexität ohne Vereins-Nutzen |
| Historisierung-Ort | Separate Zuordnungstabelle `x_gl_adresse` | Mitglied-Stammdaten bleiben sauber |
| Adress-Datensatz | Immutable per Trigger | Historie sonst inkonsistent |
| Tippfehler-Korrektur | Eigene SP `sp_adresse_korrigieren` | Einziger legitimer Änderungs-Pfad |
| Umzug vs. Korrektur | Zwei getrennte Fach-Operationen | Semantische Klarheit |
| Haushalt-Konzept | Implizit über geteilte `adresse_id` | Kein eigener Typ nötig |
| Haushalts-Umzug | Eigene Operation `MoveHousehold` | Atomar für alle betroffenen Mitglieder |
| Austritt | Ändert Adresse nicht | Ex-Mitglied wohnt weiter dort |
| DSGVO-Löschung | Anonymisieren, nicht löschen | AO §147 Aufbewahrungspflicht |
| Land-Support | `d_land` Lookup mit PLZ-Regex | Internationale Mitglieder möglich |
| PLZ-Feld | `VARCHAR(10)` | DE 5 / AT 4 / CH 4 / GB bis 8 alphanum. |
| Hausnummer | NULL zulässig mit CHECK-Constraint | Postfach, "an der alten Mühle" |
| Vereinsheim | Eigene Tabelle `m_vereinsheim` | Erweiterbar (Kapazität, Hausmeister …) |
| Sportstätten-Buchung | Nicht in diesem Design | Eigenes Modul, nicht beauftragt |

</details>

---

## 4. DB-Design

<details>
<summary>Tabellen, Beziehungen, vollständige DDL</summary>

### 4.1 Tabellen-Übersicht

| Tabelle | Rolle |
|---|---|
| `d_land` | Lookup: Länder + PLZ-Regex |
| `d_ort` | Lookup: PLZ/Ort länderabhängig |
| `m_adresse` | Adress-Stammdaten (immutable) |
| `x_gl_adresse` | Zuordnung Mitglied ↔ Adresse + Historie |
| `m_sportstaette` | Sportstätte / Veranstaltungsort |
| `m_vereinsheim` | Vereinsheim als Objekt |
| `d_ygrp` (erweitert) | `vereinssitz_adresse_id` ergänzt |

### 4.2 Beziehungen

```
d_land ◄── d_ort ◄── m_adresse ◄─┬── x_gl_adresse ──► m_gl
                                  ├── m_sportstaette
                                  ├── m_vereinsheim ──► d_ygrp
                                  └── d_ygrp (vereinssitz_adresse_id)
```

### 4.3 Zentrale Konstrukte

- Filter-Unique-Index `uq_x_gl_adresse_aktiv WHERE gueltig_bis IS NULL` — max. eine aktive Adresse pro Mitglied
- Immutable-Trigger `tr_m_adresse_immutable` — UPDATE nur via SP mit CONTEXT_INFO
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


-- ─── 3. VEREINS-OBJEKTE ─────────────────────────────────────────────

CREATE TABLE [yam3].[m_sportstaette] (
    sportstaette_id   INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_sportstaette PRIMARY KEY,
    bezeichnung       NVARCHAR(200) NOT NULL,
    beschreibung      NVARCHAR(500)     NULL,
    adresse_id        INT           NOT NULL CONSTRAINT fk_m_sportstaette_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    ist_vereinseigen  BIT           NOT NULL CONSTRAINT df_m_sportstaette_eigen DEFAULT 0
);
GO

CREATE TABLE [yam3].[m_vereinsheim] (
    vereinsheim_id  INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_vereinsheim PRIMARY KEY,
    name            NVARCHAR(200) NOT NULL,
    adresse_id      INT           NOT NULL CONSTRAINT fk_m_vereinsheim_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    ygrp_id         INT           NOT NULL CONSTRAINT fk_m_vereinsheim_ygrp    REFERENCES [yam3].[d_ygrp](id)
);
GO


-- ─── 4. ERWEITERUNG BESTEHENDER TABELLEN ────────────────────────────

ALTER TABLE [yam3].[d_ygrp]
    ADD vereinssitz_adresse_id INT NULL
        CONSTRAINT fk_d_ygrp_vereinssitz REFERENCES [yam3].[m_adresse](adresse_id);
GO


-- ─── 5. SEED: MINIMAL ───────────────────────────────────────────────

INSERT INTO [yam3].[d_land] (iso_code, bezeichnung, plz_regex) VALUES
    ('DE', 'Deutschland', '^\d{5}$'),
    ('AT', 'Österreich',  '^\d{4}$'),
    ('CH', 'Schweiz',     '^\d{4}$');
GO
```

</details>

</details>

---

## 5. Migrations-Pfad

<details>
<summary>5 Phasen vom Ist-Zustand zum Ziel</summary>

Existierendes `m_gl` enthält `str`, `plz`, `ort`. Diese Spalten bleiben während der Übergangsphase bestehen.

| Phase | Aktion | Breaking? |
|---|---|---|
| 1 | Neue Tabellen anlegen | Nein |
| 2 | Migrations-Skript: vorhandene `m_gl`-Adressdaten in `m_adresse` + `x_gl_adresse` überführen | Nein |
| 3 | Repository neu: Schreibzugriff auf neue Tabellen, Leseabfrage fällt bei leerem Ergebnis auf alte Spalten zurück | Nein |
| 4 | UI-Umstellung auf neue Struktur | Nein |
| 5 | Stichtag: alte Spalten `DROP COLUMN` | Ja — nur mit DB-Projekt machbar |

Die Breaking-Change-Phase 5 setzt ein eingeführtes DB-Projekt voraus (siehe Abschnitt 6).

</details>

---

## 6. Voraussetzung: DB-Projekt

<details>
<summary>SSDT-Einführung, Struktur, Workflow, ca. 1 Arbeitstag</summary>

Im Teams-Gespräch wurde angemerkt, dass ein DB-Projekt noch fehlt und Schema-Drift bereits sichtbar ist. Das Design der Adress-Infrastruktur bringt sechs neue Tabellen und eine Änderung an `d_ygrp` — ohne versioniertes Schema vergrößert sich die Drift. Die Einführung eines SQL Server Database Projects (SSDT) wird daher vor oder parallel zur Umsetzung empfohlen.

### 6.1 Struktur

```
yam2.sln
├── yam2/                         # WPF-App (bestehend)
└── yam2.Database/                # NEU: SSDT-Projekt
    ├── yam3/
    │   ├── Tables/               # m_gl.sql, m_adresse.sql, x_gl_adresse.sql, …
    │   ├── Views/
    │   ├── StoredProcedures/
    │   ├── Triggers/             # tr_f_ist_auto_close.sql, tr_m_adresse_immutable.sql
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
| 4 | Post-Deployment-Skript für Seed-Daten (`d_perm`, `d_role`, `d_anr`, `d_sta`, …) | 1–2 h |
| 5 | Schema-Compare gegen Live-DB, Drift dokumentieren und synchronisieren | 2 h |
| 6 | Git-Commit — ab hier alle Schema-Änderungen nur über Projekt | — |

Gesamt: ca. 1 Arbeitstag initial.

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

## 7. Offene Entscheidungen

<details>
<summary>7 Punkte zur Freigabe</summary>

| # | Frage | Vorschlag |
|---|---|---|
| 1 | `m_gl` langfristig → `m_mitglied` umbenennen, mit allen FK-Spalten `gl_id → mitglied_id` | Ja, in separater Migration nach Adress-Abschluss |
| 2 | Bestehende `m_gl`-Kürzel (`vn`, `nn`, `tel`, `mail`, `geb`) jetzt ausschreiben oder später | Später, gemeinsam mit Punkt 1 |
| 3 | `d_ort` vorbefüllen (~8000 DE-PLZ) oder on-demand beim Speichern anlegen | On-demand, wächst organisch |
| 4 | PLZ-Validierung per `d_land.plz_regex` in UI-Schicht aktivieren | Ja, verhindert Müll-Daten |
| 5 | DB-Projekt vor der Adress-Implementierung aufsetzen | Ja |
| 6 | DSGVO-Anonymisierung: Felder auf NULL oder Platzhalter ("anonymisiert") | Platzhalter, bessere Diagnose in Listen |
| 7 | Vereinsheim als eigene Tabelle `m_vereinsheim` (statt zwei Spalten in `d_ygrp`) | Ja, zukunftsfähig |

</details>

---

## 8. Nicht-Ziele

<details>
<summary>Bewusste Scope-Grenzen</summary>

Die folgenden Themen sind nicht Teil dieses Designs und werden auf separate Anforderung umgesetzt:

- Sportstätten-Buchungen / Raumbelegung
- Adress-Zugriffs-Audit (DSGVO Art. 30)
- Mehrere parallele Adressen pro Mitglied
- Vereinssitz-Historisierung

Die Struktur ist so gewählt, dass jedes dieser Themen ohne Breaking Change ergänzt werden kann.

</details>
