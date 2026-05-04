# yam2 — Adress-Infrastruktur

**Stand:** 04.05.2026
**Autor:** Ovaya

Design der Adress-Infrastruktur für yam2 aus dem Teams-Gespräch vom 20.04.2026.
Aufbau: Anwendungsfälle → Logik → DB-Design → Umsetzungsplan.
Abschnitte einklappbar; Inhaltsverzeichnis für gezielte Navigation.

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

* `d_ygrp` soll die Möglichkeit haben, ein Vereinsheim zu definieren
* Der Verein braucht einen Sitz
* Sportstätten sind Orte, an denen bestimmte Tätigkeiten stattfinden (Beispiel: Handball, Turnen in Sporthalle Beispielstraße 3)
* Anwendungsfälle und Logik zusammenschreiben — insbesondere Historisierung und mehrere Mitglieder an gleicher Adresse
* Erst Design, dann Implementierung
* Reihenfolge: Kundenanforderung → Functional Specs → Technical Specs → DB-Design → Implementierung

Abbildung im Dokument: Abschnitt 2 = Functional Specs, Abschnitt 3 = Technical Specs, Abschnitt 4 = DB-Design.

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
<summary>15 Entscheidungen mit Begründung</summary>

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

* Filter-Unique-Index `uq_x_gl_adresse_aktiv WHERE gueltig_bis IS NULL` — max. eine aktive Adresse pro Mitglied
* Immutable-Trigger `tr_m_adresse_immutable` — UPDATE nur via SP mit CONTEXT\_INFO
* CHECK-Constraint `ck_m_adresse_mindestangabe` — Hausnummer oder Adresszusatz gesetzt
* Dedupe-Index `uq_m_adresse_physisch` — identische Adressen nur einmal

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
    ist_vereinseigen  BIT           NOT NULL CONSTRAINT df_m_sportstaette_eigen DEFAULT 0,
    erstellt_am       DATETIME2     NOT NULL CONSTRAINT df_m_sportstaette_erstellt DEFAULT SYSUTCDATETIME(),
    erstellt_von      NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE [yam3].[m_vereinsheim] (
    vereinsheim_id  INT           NOT NULL IDENTITY(1,1) CONSTRAINT pk_m_vereinsheim PRIMARY KEY,
    name            NVARCHAR(200) NOT NULL,
    adresse_id      INT           NOT NULL CONSTRAINT fk_m_vereinsheim_adresse REFERENCES [yam3].[m_adresse](adresse_id),
    ygrp_id         INT           NOT NULL CONSTRAINT fk_m_vereinsheim_ygrp    REFERENCES [yam3].[d_ygrp](id),
    erstellt_am     DATETIME2     NOT NULL CONSTRAINT df_m_vereinsheim_erstellt DEFAULT SYSUTCDATETIME(),
    erstellt_von    NVARCHAR(100) NOT NULL
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

**Live-DB-Status (Stand 2026-04-21, 10 Mitglieder):**

* `m_gl.str`, `m_gl.plz`, `m_gl.ort` sind alle nullable — nicht jedes Mitglied hat Adressdaten
* Neue Tabellen (`m_adresse`, `x_gl_adresse`, `d_ort`, `d_land`, `m_sportstaette`, `m_vereinsheim`) noch nicht deployed
* `d_ygrp` hat noch kein `vereinssitz_adresse_id`

| Phase | Aktion | Breaking? |
|---|---|---|
| 1 | Neue Tabellen anlegen (DDL aus Abschnitt 4.4) | Nein |
| 2 | Migrations-Skript: `m_gl`-Adressdaten in `m_adresse` + `x_gl_adresse` überführen — **nur Mitglieder mit mind. einem gesetzten Adressfeld** (`str` oder `plz` oder `ort` NOT NULL); leere Adressdatensätze werden übersprungen | Nein |
| 3 | Repository neu: Schreibzugriff auf neue Tabellen, Leseabfrage fällt bei leerem `x_gl_adresse`-Ergebnis auf alte `m_gl`-Spalten zurück | Nein |
| 4 | UI-Umstellung auf neue Struktur | Nein |
| 5 | Stichtag: alte Spalten `DROP COLUMN` (`str`, `plz`, `ort`) | Ja — nur mit DB-Projekt machbar |

**Typ-Hinweis Phase 2:** `m_gl.str` ist `NVARCHAR(100) nullable`, `m_adresse.strasse` ist `NVARCHAR(100) NOT NULL`. Beim Migrieren muss ein nicht-null `str` vorhanden sein — andernfalls keinen `m_adresse`-Eintrag anlegen.

Phase 5 (Breaking Change) setzt ein eingeführtes DB-Projekt voraus (siehe Abschnitt 6).

</details>

---

## 6. Voraussetzung: DB-Projekt

<details>
<summary>SSDT-Einführung — Status, Befunde, offene Schritte</summary>

**Teams-Anmerkung:** DB-Projekt fehlt, Schema-Drift bereits sichtbar.
**Ansatz:** Die Adress-Infrastruktur bringt sechs neue Tabellen und eine Änderung an `d_ygrp` — ohne versioniertes Schema vergrößert sich die Drift. Ein SQL Server Database Project (SSDT) wird daher vor oder parallel zur Umsetzung eingeführt.

### 6.1 Aktueller Status (Stand 04.05.2026)

| # | Schritt | Status |
|---|---|---|
| 1 | SSDT-Projekt `yam2.Database` in Solution anlegen | ✅ erledigt |
| 2 | Schema-Import aus `SauerSQL2.ovaya_test` via SQL-Skript | ✅ erledigt — 92 Anweisungen importiert |
| 3 | Build — DACPAC erzeugen, Validierungsfehler beheben | ⏳ ausstehend — Build noch nicht durchgeführt |
| 4 | Post-Deployment-Skript für Seed-Daten (`d_perm`, `d_role`, `d_anr`, `d_sta`, …) | ⏳ ausstehend |
| 5 | Schema-Compare gegen Live-DB, Drift dokumentieren | ⏳ ausstehend |
| 6 | Git-Commit — ab hier alle Schema-Änderungen nur über Projekt | ⏳ ausstehend |

### 6.2 Befunde aus dem Import

**DSP-Mismatch — wichtig:**

```
Projekt-Zielplattform:  Sql130  (SQL Server 2016)
Live-DB:                Sql160  (SQL Server 2022)
```

Der Import-Wizard hat Sql130 gewählt, weil DACPAC-Import via VS 2017 mit `Sql160DatabaseSchemaProvider` fehlschlug (fehlender Provider). Das Projekt läuft mit Sql130, was für yam2 akzeptabel ist — SQL Server 2022 ist abwärtskompatibel. Einzige Einschränkung: SQL-2022-spezifische Syntax (z.B. `IS [NOT] DISTINCT FROM`) wird im Build als Fehler markiert. Aktuell betrifft das keinen Code.

**Bekannte Schema-Drift im `dbo`-Schema:**

Die DB enthält Tabellen aus früheren Lernprojekten, die nicht zu yam2 gehören:

```
dbo.__EFMigrationsHistory    ← EF Core Migrations-Artefakt
dbo.Adressen                 ← EF-Lernprojekt (englische Spaltennamen, uniqueidentifier PK)
dbo.Members                  ← EF-Lernprojekt
dbo.Roles                    ← EF-Lernprojekt
dbo.Users                    ← EF-Lernprojekt
dbo.Animal / Zoo / ZooAnimal2 ← Übungs-Tabellen
dbo.Currency_Master          ← Übungs-Tabelle
dbo.tt1 / tt2 / tt_artiel    ← Übungs-Tabellen
yam2.Members                 ← Vorläufer-Schema, historisch
```

Diese sind im SSDT-Projekt enthalten, gehören aber nicht zu yam2. Empfehlung: im Projekt belassen (kein aktives Löschen), aber beim Schema-Compare ignorieren (`dbo`-Schema aus Compare ausschließen).

**Importierter yam3-Stand:**

Alle produktiven Tabellen erfolgreich importiert:

```
yam3: d_anr, d_perm, d_role, d_sta, d_ybart, d_yfun, d_ygrp, d_ykto,
      d_ysolltyp, d_zart, f_ist (inkl. Trigger tr_f_ist_auto_close),
      f_soll, m_gl, m_jump, m_mark, m_u, t_reg, x_fa, x_gm, x_rp, x_ur
      Views:  v_user_perms
      SPs:    sp_multiplier_soll
```

**Neue Adress-Tabellen noch nicht im Projekt** (folgen in Migrations-Phase 1):
```
yam3: d_land, d_ort, m_adresse, x_gl_adresse, m_sportstaette, m_vereinsheim
      d_ygrp.vereinssitz_adresse_id  ← ALTER TABLE noch nicht deployed
```

### 6.3 Projekt-Struktur (aktuell)

```
yam2.sln
├── yam2/                              # WPF-App (bestehend)
└── yam2.Database/                     # SSDT-Projekt ✅
    ├── yam3/
    │   ├── Tables/                    # 20 Tabellen ✅
    │   ├── Views/                     # v_user_perms ✅
    │   ├── Stored Procedures/         # sp_multiplier_soll ✅
    │   └── (Trigger in f_ist.sql)     # tr_f_ist_auto_close ✅
    ├── dbo/Tables/                    # Lernprojekt-Rauschen (nicht löschen)
    ├── yam2/Tables/                   # Altlast-Schema (nicht löschen)
    ├── Security/                      # yam2.sql, yam3.sql (Schema-Definitionen)
    ├── Scripts/
    │   └── ScriptsIgnoredOnImport.sql # DB-Level-Settings, ignoriert
    └── yam2.Database.sqlproj          # DSP: Sql130
```

### 6.4 Nächste Schritte im DB-Projekt

```
1. Build ausführen → Fehler dokumentieren und beheben
2. Adress-DDL (Phase 1) als neue .sql-Dateien anlegen:
     yam3/Tables/d_land.sql
     yam3/Tables/d_ort.sql
     yam3/Tables/m_adresse.sql
     yam3/Tables/x_gl_adresse.sql
     yam3/Tables/m_sportstaette.sql
     yam3/Tables/m_vereinsheim.sql
3. d_ygrp.sql um vereinssitz_adresse_id ergänzen
4. Git-Commit: "feat(db): SSDT-Projekt + Adress-Schema Phase 1"
5. Schema-Compare gegen Live-DB (dbo-Schema ignorieren)
```

### 6.5 Workflow ab jetzt

Neue Tabelle oder Schema-Änderung:

1. SQL-Datei im DB-Projekt anlegen oder ändern
2. Build — DACPAC wird erzeugt
3. Git-Commit
4. Deployment via Schema Compare oder `sqlpackage.exe /Publish`
5. Rollback über vorherigen DACPAC-Stand

Breaking Changes (Umbenennung, `DROP COLUMN`) werden über Pre- und Post-Deployment-Skripte mit Datenmigration abgesichert.

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
| 5 | DB-Projekt vor der Adress-Implementierung aufsetzen | ✅ erledigt (04.05.2026) |
| 6 | DSGVO-Anonymisierung: Felder auf NULL oder Platzhalter ("anonymisiert") | Platzhalter, bessere Diagnose in Listen |
| 7 | Vereinsheim als eigene Tabelle `m_vereinsheim` (statt zwei Spalten in `d_ygrp`) | Ja, zukunftsfähig |

</details>

---

## 8. Nicht-Ziele

<details>
<summary>Bewusste Scope-Grenzen</summary>

Nicht Teil dieses Designs — ggf. auf separate Anforderung:

* Sportstätten-Buchungen / Raumbelegung
* Vollständige DSGVO-Compliance (Zweckbindung pro Adresse, Einwilligungsmanagement, Verarbeitungs-Einschränkung nach Art. 18)
* Adress-Zugriffs-Audit (DSGVO Art. 30)
* Polymorphe Adress-Zuordnung (für Lieferanten, Behörden, externe Partner)
* Mehrere parallele Adressen pro Mitglied (Rechnungs-, Post-, Lieferadresse)
* Vereinssitz-Historisierung

Struktur ist so gewählt, dass jedes dieser Themen ohne Breaking Change ergänzt werden kann.

</details>
