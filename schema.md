<!-- schema.md — v2.1.0 — Korrekturen aus der Gesamtprüfung: ON DELETE zweier RBAC-Verweise, Zugriff im Code vollständig, erledigt-Logik, Geltungsbereich, restliche Kürzel -->
<!-- erzeugt mit tools/schema_extract.py 1.1.0 und tools/schema_render.py 1.1.0; nicht von Hand ändern, sondern Quelle oder doku-config.json anpassen -->

# yam3 — Datenbankschema (Soll-Stand)

Schema: `[yam3]` | Quelle: Datenbankprojekt `yam2.Database`, Branch `feature/gruppe-sitzspalte-entfernen`, Stand `d1dfd1b` | Stand: 2026-10-07

> **Geltungsbereich:** Die Namen und Tabellen in diesem Dokument entsprechen dem Datenbankprojekt (Soll-Stand des genannten Branches). Datenbanken, die noch nicht auf diesen Stand veröffentlicht sind, tragen die alten Namen (Zuordnung in Abschnitt 3) und können Tabellen und Spalten eines älteren Entwurfs enthalten oder neue Tabellen noch nicht enthalten.

---

## 1 Überblick

**28 Tabellen**, 140 Spalten, 30 Fremdschlüssel, 3 Trigger, 2 Stored Procedures, 1 Sicht.

| Präfix | Bedeutung | Anzahl | Tabellen |
|---|---|---|---|
| `d_` | Lookup-Tabellen (Dimensionen) | 13 | `d_anrede`, `d_beitragsart`, `d_gruppe`, `d_konto`, `d_land`, `d_objekttyp`, `d_ort`, `d_perm`, `d_role`, `d_solltyp`, `d_status`, `d_yfun`, `d_zahlungsart` |
| `f_` | Faktentabellen (Bewegungsdaten) | 2 | `f_ist`, `f_soll` |
| `m_` | Mastertabellen (Stammdaten) | 6 | `m_adresse`, `m_jump`, `m_mark`, `m_mitglied`, `m_objekt`, `m_user` |
| `t_` | Technische Tabellen | 1 | `t_reg` |
| `x_` | Zuordnungstabellen (n:m) | 6 | `x_fa`, `x_gruppe_mitglied`, `x_mitglied_adresse`, `x_objekt_gruppe`, `x_role_perm`, `x_user_role` |

Lesehilfe: **PK** Primärschlüssel · **FK** Fremdschlüssel (→ Zieltabelle) · **UK** eindeutig · **IDENTITY** automatisch hochgezählt. Die Spalte „C#“ nennt die Property, die der Code per Spaltenname liest (nur wo das im Code eindeutig erkennbar ist).
„Zugriff im Code“ nennt die Dateien unter yam2/Services (*.cs, ohne Kommentare), die den Tabellennamen als `[yam3].[name]` oder als eigenes String-Literal enthalten; „kein Treffer“ heißt: dort nicht gefunden.

---

## 2 Tabellen

### Lookup-Tabellen (Dimensionen), Präfix `d_`

#### `[yam3].[d_anrede]`

Anreden; die IDs entsprechen dem C#-Enum `Anrede`

früher `d_anr` · Datei `d_anr.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(20)` | **nein** | – | früher `bez` |

#### `[yam3].[d_beitragsart]`

Beitragsarten mit Standardbetrag

früher `d_ybart` · Datei `d_ybart.sql` · Zugriff im Code: `SqlFinanceRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | früher `bez` |
| `standard_betrag` | `decimal(8,2)` | **nein** | `0` | früher `std_betrag` |

#### `[yam3].[d_gruppe]`

Gruppen und Abteilungen

früher `d_ygrp` · Datei `d_ygrp.sql` · Zugriff im Code: `SqlGroupRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | früher `bez` |

#### `[yam3].[d_konto]`

Vereinskonten (optional mit IBAN)

früher `d_ykto` · Datei `d_ykto.sql` · Zugriff im Code: `SqlFinanceRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | früher `bez` |
| `iban` | `nvarchar(34)` | ja | – |  |

#### `[yam3].[d_land]`

Länder mit ISO-Code und PLZ-Muster

Datei `d_land.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `land_id` | `int` | **nein** | – | IDENTITY; PK |
| `iso_code` | `char(2)` | **nein** | – | UK |
| `bezeichnung` | `nvarchar(100)` | **nein** | – |  |
| `plz_regex` | `nvarchar(100)` | ja | – |  |

- UNIQUE `uq_d_land_iso` (`iso_code`)

#### `[yam3].[d_objekttyp]`

Typ eines Vereinsobjekts (1 Vereinsheim, 2 Sportstätte, 3 Lager, 4 Sonstige); Seed in `d_objekttyp_seed.sql`

Datei `d_objekttyp.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `objekttyp_id` | `int` | **nein** | – | PK |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | UK |

- UNIQUE `uq_d_objekttyp_bezeichnung` (`bezeichnung`)

#### `[yam3].[d_ort]`

PLZ und Ort, abhängig vom Land

Datei `d_ort.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `ort_id` | `int` | **nein** | – | IDENTITY; PK |
| `land_id` | `int` | **nein** | – | FK → `d_land.land_id` |
| `plz` | `varchar(10)` | **nein** | – |  |
| `ort` | `nvarchar(100)` | **nein** | – |  |
| `bundesland` | `nvarchar(50)` | ja | – |  |

- UNIQUE `uq_d_ort_kombi` (`land_id`, `plz`, `ort`)
- Index `ix_d_ort_plz` (`plz`)

#### `[yam3].[d_perm]`

Berechtigungen; `perm_key` im Format `modul.aktion`

Datei `d_perm.sql` · C#-Klasse `Permission` · Zugriff im Code: `SqlRoleRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung | C# |
|---|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |  |
| `perm_key` | `nvarchar(50)` | **nein** | – | UK | `PermKey` |
| `modul` | `nvarchar(30)` | **nein** | – |  | `Modul` |
| `aktion` | `nvarchar(20)` | **nein** | – |  | `Aktion` |
| `bezeichnung` | `nvarchar(100)` | **nein** | – | früher `bez` |  |

- UNIQUE `UQ_d_perm_key` (`perm_key`)

#### `[yam3].[d_role]`

Rollen (RBAC); `is_superadmin` = jede Berechtigungsprüfung gilt als erfüllt, `is_system` = in der Oberfläche nicht bearbeit- und nicht löschbar (keine Sperre in der Datenbank)

Datei `d_role.sql` · C#-Klasse `Role` · Zugriff im Code: `SqlRoleRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung | C# |
|---|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK | `Id` |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | UK; früher `bez` | `Bezeichnung` |
| `beschreibung` | `nvarchar(200)` | ja | – |  | `Beschreibung` |
| `is_superadmin` | `bit` | **nein** | `0` |  | `IsSuperadmin` |
| `is_system` | `bit` | **nein** | `0` |  | `IsSystem` |

- UNIQUE `UQ_d_role_bez` (`bezeichnung`)

#### `[yam3].[d_solltyp]`

Typen von Soll-Buchungen

früher `d_ysolltyp` · Datei `d_ysolltyp.sql` · Zugriff im Code: `SqlFinanceRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | früher `bez` |

#### `[yam3].[d_status]`

Mitgliedsstatus; die IDs entsprechen dem C#-Enum `MemberStatus`

früher `d_sta` · Datei `d_sta.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(50)` | **nein** | – | früher `bez` |

#### `[yam3].[d_yfun]`

Funktionen und Ämter

Datei `d_yfun.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bez` | `nvarchar(50)` | **nein** | – |  |

#### `[yam3].[d_zahlungsart]`

Zahlungsarten; die IDs entsprechen dem C#-Enum `Zahlungsart`

früher `d_zart` · Datei `d_zart.sql` · Zugriff im Code: `SqlFinanceRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(30)` | **nein** | – | früher `bez` |

### Faktentabellen (Bewegungsdaten), Präfix `f_`

#### `[yam3].[f_ist]`

Zahlungen (Ist)

Datei `f_ist.sql` · C#-Klasse `Payment` · Zugriff im Code: `SqlFinanceRepository`, `SqlHomeRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung | C# |
|---|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK | `Id` |
| `soll_id` | `int` | ja | – | FK → `f_soll.id` | `SollId` |
| `konto_id` | `int` | **nein** | `1` | FK → `d_konto.id`; früher `ykto_id` | `YktoId` |
| `zahlungsart_id` | `int` | **nein** | `1` | FK → `d_zahlungsart.id`; früher `zart_id` | `ZartId` |
| `betrag` | `decimal(8,2)` | **nein** | – |  | `Amount` |
| `datum` | `date` | **nein** | `getdate()` |  | `Date` |
| `text` | `nvarchar(100)` | ja | – |  | `Text` |
| `batch_id` | `uniqueidentifier` | ja | – |  | `BatchId` |

#### `[yam3].[f_soll]`

Gebühren (Soll); `erledigt` wird beim Anlegen mit 0 geschrieben und danach nur vom Trigger `tr_f_ist_auto_close` neu berechnet (bei INSERT und UPDATE auf `f_ist`); eine Änderung von `betrag` hier oder das Löschen einer Zahlung berechnet es nicht neu

Datei `f_soll.sql` · C#-Klasse `Fee` · Zugriff im Code: `SqlFinanceRepository`, `SqlHomeRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung | C# |
|---|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK | `Id` |
| `mitglied_id` | `int` | **nein** | – | FK → `m_mitglied.id`; früher `gl_id` | `MemberId` |
| `beitragsart_id` | `int` | **nein** | – | FK → `d_beitragsart.id`; früher `ybart_id` | `YbartId` |
| `solltyp_id` | `int` | **nein** | `1` | FK → `d_solltyp.id`; früher `ysolltyp_id` | `YsolltypId` |
| `jahr` | `int` | **nein** | – |  | `Year` |
| `betrag` | `decimal(8,2)` | **nein** | – |  | `Amount` |
| `zweck` | `nvarchar(100)` | **nein** | – |  | `Purpose` |
| `faellig` | `date` | **nein** | – |  | `DueDate` |
| `erledigt` | `bit` | **nein** | `0` |  | `IsDone` |
| `batch_id` | `uniqueidentifier` | ja | – |  | `BatchId` |

### Mastertabellen (Stammdaten), Präfix `m_`

#### `[yam3].[m_adresse]`

Adress-Stammdaten, unveränderlich; Korrekturen nur über `sp_adresse_korrigieren`

Datei `m_adresse.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `adresse_id` | `int` | **nein** | – | IDENTITY; PK |
| `strasse` | `nvarchar(100)` | **nein** | – |  |
| `hausnummer` | `nvarchar(10)` | ja | – |  |
| `adresszusatz` | `nvarchar(100)` | **nein** | `''` |  |
| `ort_id` | `int` | **nein** | – | FK → `d_ort.ort_id` |
| `erstellt_am` | `datetime2` | **nein** | `SYSUTCDATETIME()` |  |
| `erstellt_von` | `nvarchar(100)` | **nein** | – |  |

- UNIQUE Index `uq_m_adresse_physisch` (`strasse`, `hausnummer`, `ort_id`, `adresszusatz`)
- CHECK `ck_m_adresse_mindestangabe` `[hausnummer] IS NOT NULL OR LEN([adresszusatz]) > 0`

#### `[yam3].[m_jump]`

Besuchsverlauf je Benutzer und Mitglied mit Zeitpunkt `besucht_am`

Datei `m_jump.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `u_id` | `int` | **nein** | – | FK → `m_user.id` |
| `mitglied_id` | `int` | **nein** | – | FK → `m_mitglied.id`; früher `gl_id` |
| `besucht_am` | `datetime` | ja | `getdate()` |  |

#### `[yam3].[m_mark]`

Markierungen (ein Zeichen `mark_char`) je Benutzer und Mitglied

Datei `m_mark.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK |
| `u_id` | `int` | **nein** | – | FK → `m_user.id` |
| `mitglied_id` | `int` | **nein** | – | FK → `m_mitglied.id`; früher `gl_id` |
| `mark_char` | `char(1)` | **nein** | – |  |
| `gesetz_am` | `datetime` | ja | `getdate()` |  |

#### `[yam3].[m_mitglied]`

Mitglieder (Stammdaten)

früher `m_gl` · Datei `m_gl.sql` · C#-Klasse `Member` · Zugriff im Code: `SqlGroupRepository`, `SqlHomeRepository`, `SqlMemberRepository`, `SqlRoleRepository`, `SqlUserRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung | C# |
|---|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK | `Id` |
| `mitglied_nr` | `nvarchar(20)` | **nein** | – | UK; früher `gl_nr` | `Mitgliedsnummer` |
| `anrede_id` | `int` | **nein** | `1` | FK → `d_anrede.id`; früher `anr_id` | `Anrede` |
| `vorname` | `nvarchar(50)` | **nein** | – | früher `vn` | `Vorname` |
| `nachname` | `nvarchar(50)` | **nein** | – | früher `nn` | `Nachname` |
| `geburtsdatum` | `date` | ja | – | früher `geb` | `Geburtstag` |
| `email` | `nvarchar(100)` | ja | – | früher `mail` | `Email` |
| `telefon` | `nvarchar(50)` | ja | – | früher `tel` | `Telefon` |
| `str` | `nvarchar(100)` | ja | – |  | `Strasse` |
| `plz` | `nvarchar(10)` | ja | – |  | `PLZ` |
| `ort` | `nvarchar(100)` | ja | – |  | `Ort` |
| `iban` | `nvarchar(34)` | ja | – |  | `IBAN` |
| `bic` | `nvarchar(11)` | ja | – |  | `BIC` |
| `sepa_referenz` | `nvarchar(35)` | ja | – | früher `sepa_ref` | `SepaReferenz` |
| `sepa_datum` | `date` | ja | – |  | `SepaDatum` |
| `status_id` | `int` | **nein** | `1` | FK → `d_status.id`; früher `sta_id` | `Status` |
| `beitragsart_id` | `int` | **nein** | `1` | FK → `d_beitragsart.id`; früher `ybart_id` | `BeitragId` |
| `eintritt` | `date` | **nein** | `getdate()` |  | `Eintrittsdatum` |
| `austritt` | `date` | ja | – |  | `Austrittsdatum` |
| `dsgvo_einwilligung_daten` | `bit` | **nein** | `0` | früher `dsgvo_dat` | `DsgvoOk` |
| `dsgvo_einwilligung_foto` | `bit` | **nein** | `0` | früher `dsgvo_foto` | `DsgvoFoto` |
| `erstellt_am` | `datetime` | ja | `getdate()` |  |  |
| `geaendert_am` | `datetime` | ja | `getdate()` |  |  |

- UNIQUE (unbenannt) (`mitglied_nr`)

#### `[yam3].[m_objekt]`

Vereinsobjekte (Vereinsheim, Sportstätte, Lager, Sonstige) in einer Tabelle; der Typ steht in `typ_id` → `d_objekttyp`; höchstens ein Sitz (`ist_sitz`) je Datenbank

Datei `m_objekt.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `objekt_id` | `int` | **nein** | – | IDENTITY; PK |
| `bezeichnung` | `nvarchar(100)` | **nein** | – |  |
| `typ_id` | `int` | **nein** | – | FK → `d_objekttyp.objekttyp_id` |
| `adresse_id` | `int` | **nein** | – | FK → `m_adresse.adresse_id` |
| `ist_sitz` | `bit` | **nein** | `0` |  |
| `ist_vereinseigen` | `bit` | **nein** | `0` |  |
| `beschreibung` | `nvarchar(500)` | ja | – |  |
| `aktiv` | `bit` | **nein** | `1` |  |
| `erstellt_am` | `datetime2` | **nein** | `SYSUTCDATETIME()` |  |
| `erstellt_von` | `nvarchar(100)` | **nein** | – |  |
| `geaendert_am` | `datetime2` | ja | – |  |
| `geaendert_von` | `nvarchar(100)` | ja | – |  |

- UNIQUE Index `uq_m_objekt_sitz` (`ist_sitz`) WHERE `[ist_sitz] = 1`

#### `[yam3].[m_user]`

Benutzer (Windows-Konto), optional einem Mitglied zugeordnet

früher `m_u` · Datei `m_u.sql` · C#-Klasse `AppUser` · Zugriff im Code: `SqlRoleRepository`, `SqlUserRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung | C# |
|---|---|---|---|---|---|
| `id` | `int` | **nein** | – | IDENTITY; PK | `Id` |
| `mitglied_id` | `int` | ja | – | FK → `m_mitglied.id`; früher `gl_id` | `GlId` |
| `win_user` | `nvarchar(100)` | **nein** | – | UK | `WinUser` |
| `is_admin` | `bit` | **nein** | `0` |  | `IsAdmin` |
| `letzter_login` | `datetime` | ja | – |  | `LetzterLogin` |

- UNIQUE (unbenannt) (`win_user`)

### Technische Tabellen, Präfix `t_`

#### `[yam3].[t_reg]`

App-Einstellungen als Schlüssel-Wert

Datei `t_reg.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `reg_name` | `char(1)` | **nein** | – | PK |
| `payload` | `nvarchar(max)` | **nein** | – |  |
| `u_id` | `int` | ja | – |  |
| `geaendert_am` | `datetime` | ja | `getdate()` |  |

### Zuordnungstabellen (n:m), Präfix `x_`

#### `[yam3].[x_fa]`

Zuordnung Mitglied ↔ Funktion

Datei `x_fa.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `mitglied_id` | `int` | **nein** | – | PK; FK → `m_mitglied.id`; früher `gl_id` |
| `yfun_id` | `int` | **nein** | – | PK; FK → `d_yfun.id` |
| `wahl` | `date` | ja | – |  |

#### `[yam3].[x_gruppe_mitglied]`

Zuordnung Mitglied ↔ Gruppe (mit Eintrittsdatum `seit`)

früher `x_gm` · Datei `x_gm.sql` · Zugriff im Code: `SqlGroupRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `mitglied_id` | `int` | **nein** | – | PK; FK → `m_mitglied.id`; früher `gl_id` |
| `gruppe_id` | `int` | **nein** | – | PK; FK → `d_gruppe.id`; früher `ygrp_id` |
| `seit` | `date` | **nein** | `getdate()` |  |

#### `[yam3].[x_mitglied_adresse]`

Zuordnung Mitglied ↔ Adresse mit Gültigkeitszeitraum (Adress-Historie)

früher `x_gl_adresse` · Datei `x_gl_adresse.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `mitglied_adresse_id` | `int` | **nein** | – | IDENTITY; PK; früher `gl_adresse_id` |
| `mitglied_id` | `int` | **nein** | – | FK → `m_mitglied.id`; früher `gl_id` |
| `adresse_id` | `int` | **nein** | – | FK → `m_adresse.adresse_id` |
| `gueltig_von` | `date` | **nein** | – |  |
| `gueltig_bis` | `date` | ja | – |  |
| `geaendert_am` | `datetime2` | **nein** | `SYSUTCDATETIME()` |  |
| `geaendert_von` | `nvarchar(100)` | **nein** | – |  |

- UNIQUE Index `uq_x_gl_adresse_aktiv` (`mitglied_id`) WHERE `[gueltig_bis] IS NULL`
- Index `ix_x_gl_adresse_zeitraum` (`mitglied_id`, `gueltig_von`, `gueltig_bis`)
- CHECK `ck_x_gl_adresse_zeitraum` `[gueltig_bis] IS NULL OR [gueltig_bis] > [gueltig_von]`

#### `[yam3].[x_objekt_gruppe]`

N:M-Verknüpfung Vereinsobjekt ↔ Gruppe/Aktivität mit Freitext-Beschreibung (z. B. „Handball jeden Dienstag 18-20 Uhr“)

Datei `x_objekt_gruppe.sql` · Zugriff im Code: kein Treffer

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `objekt_id` | `int` | **nein** | – | PK; FK → `m_objekt.objekt_id` |
| `ygrp_id` | `int` | **nein** | – | PK; FK → `d_gruppe.id` |
| `beschreibung` | `nvarchar(200)` | ja | – |  |
| `erstellt_am` | `datetime2` | **nein** | `SYSUTCDATETIME()` |  |
| `erstellt_von` | `nvarchar(100)` | **nein** | – |  |

#### `[yam3].[x_role_perm]`

Zuordnung Rolle ↔ Berechtigung

früher `x_rp` · Datei `x_rp.sql` · Zugriff im Code: `SqlRoleRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `role_id` | `int` | **nein** | – | PK; FK → `d_role.id` |
| `perm_id` | `int` | **nein** | – | PK; FK → `d_perm.id` |

#### `[yam3].[x_user_role]`

Zuordnung Benutzer ↔ Rolle

früher `x_ur` · Datei `x_ur.sql` · Zugriff im Code: `SqlRoleRepository`

| Spalte | Typ | Null | Default | Schlüssel / Bemerkung |
|---|---|---|---|---|
| `user_id` | `int` | **nein** | – | PK; FK → `m_user.id`; früher `u_id` |
| `role_id` | `int` | **nein** | – | PK; FK → `d_role.id` |
| `zugewiesen_am` | `datetime` | **nein** | `getdate()` |  |

---

## 3 Namens-Zuordnung alt → neu

Quelle: Refactorlog des Datenbankprojekts (49 Umbenennungen). Die Namen von Constraints und Indizes wurden dabei nicht geändert.

### Tabellen

| Alt | Neu |
|---|---|
| `d_anr` | `d_anrede` |
| `d_sta` | `d_status` |
| `d_zart` | `d_zahlungsart` |
| `d_ybart` | `d_beitragsart` |
| `d_ykto` | `d_konto` |
| `d_ysolltyp` | `d_solltyp` |
| `d_ygrp` | `d_gruppe` |
| `x_gm` | `x_gruppe_mitglied` |
| `m_u` | `m_user` |
| `x_ur` | `x_user_role` |
| `x_rp` | `x_role_perm` |
| `m_gl` | `m_mitglied` |
| `x_gl_adresse` | `x_mitglied_adresse` |

### Spalten

| Tabelle (neu) | Alt | Neu |
|---|---|---|
| `d_anrede` | `bez` | `bezeichnung` |
| `d_beitragsart` | `bez` | `bezeichnung` |
| `d_beitragsart` | `std_betrag` | `standard_betrag` |
| `d_gruppe` | `bez` | `bezeichnung` |
| `d_konto` | `bez` | `bezeichnung` |
| `d_perm` | `bez` | `bezeichnung` |
| `d_role` | `bez` | `bezeichnung` |
| `d_solltyp` | `bez` | `bezeichnung` |
| `d_status` | `bez` | `bezeichnung` |
| `d_zahlungsart` | `bez` | `bezeichnung` |
| `f_ist` | `zart_id` | `zahlungsart_id` |
| `f_ist` | `ykto_id` | `konto_id` |
| `f_soll` | `ybart_id` | `beitragsart_id` |
| `f_soll` | `ysolltyp_id` | `solltyp_id` |
| `f_soll` | `gl_id` | `mitglied_id` |
| `m_jump` | `gl_id` | `mitglied_id` |
| `m_mark` | `gl_id` | `mitglied_id` |
| `m_mitglied` | `vn` | `vorname` |
| `m_mitglied` | `nn` | `nachname` |
| `m_mitglied` | `geb` | `geburtsdatum` |
| `m_mitglied` | `tel` | `telefon` |
| `m_mitglied` | `mail` | `email` |
| `m_mitglied` | `sepa_ref` | `sepa_referenz` |
| `m_mitglied` | `dsgvo_dat` | `dsgvo_einwilligung_daten` |
| `m_mitglied` | `dsgvo_foto` | `dsgvo_einwilligung_foto` |
| `m_mitglied` | `anr_id` | `anrede_id` |
| `m_mitglied` | `sta_id` | `status_id` |
| `m_mitglied` | `ybart_id` | `beitragsart_id` |
| `m_mitglied` | `gl_nr` | `mitglied_nr` |
| `m_user` | `gl_id` | `mitglied_id` |
| `x_fa` | `gl_id` | `mitglied_id` |
| `x_gruppe_mitglied` | `ygrp_id` | `gruppe_id` |
| `x_gruppe_mitglied` | `gl_id` | `mitglied_id` |
| `x_mitglied_adresse` | `gl_id` | `mitglied_id` |
| `x_mitglied_adresse` | `gl_adresse_id` | `mitglied_adresse_id` |
| `x_user_role` | `u_id` | `user_id` |

### Hinweise (automatisch ermittelt)

- Spalten mit einem alten Kürzel im Namen: `m_jump.u_id`, `m_mark.u_id`, `t_reg.u_id`, `x_fa.yfun_id`, `x_objekt_gruppe.ygrp_id`.
- Tabellen mit Kürzel im Namen, die im Refactorlog nicht umbenannt wurden: `d_yfun`, `x_fa`.

---

## 4 Fremdschlüssel (alle)

| Von | Spalte | → Nach | ON DELETE | Name |
|---|---|---|---|---|
| `d_ort` | `land_id` | `d_land.land_id` | NO ACTION | `fk_d_ort_land` |
| `f_ist` | `konto_id` | `d_konto.id` | NO ACTION | `FK_f_ist_d_ykto` |
| `f_ist` | `zahlungsart_id` | `d_zahlungsart.id` | NO ACTION | `FK_f_ist_d_zart` |
| `f_ist` | `soll_id` | `f_soll.id` | NO ACTION | `FK_f_ist_f_soll` |
| `f_soll` | `beitragsart_id` | `d_beitragsart.id` | NO ACTION | `FK_f_soll_d_ybart` |
| `f_soll` | `solltyp_id` | `d_solltyp.id` | NO ACTION | `FK_f_soll_d_ysolltyp` |
| `f_soll` | `mitglied_id` | `m_mitglied.id` | **CASCADE** | `FK_f_soll_m_gl` |
| `m_adresse` | `ort_id` | `d_ort.ort_id` | NO ACTION | `fk_m_adresse_ort` |
| `m_jump` | `mitglied_id` | `m_mitglied.id` | **CASCADE** | `FK_jump_gl` |
| `m_jump` | `u_id` | `m_user.id` | NO ACTION | `FK_jump_u` |
| `m_mark` | `mitglied_id` | `m_mitglied.id` | **CASCADE** | `FK_mark_gl` |
| `m_mark` | `u_id` | `m_user.id` | NO ACTION | `FK_mark_u` |
| `m_mitglied` | `anrede_id` | `d_anrede.id` | NO ACTION | `FK_m_gl_d_anr` |
| `m_mitglied` | `status_id` | `d_status.id` | NO ACTION | `FK_m_gl_d_sta` |
| `m_mitglied` | `beitragsart_id` | `d_beitragsart.id` | NO ACTION | `FK_m_gl_d_ybart` |
| `m_objekt` | `typ_id` | `d_objekttyp.objekttyp_id` | NO ACTION | `fk_m_objekt_typ` |
| `m_objekt` | `adresse_id` | `m_adresse.adresse_id` | NO ACTION | `fk_m_objekt_adresse` |
| `m_user` | `mitglied_id` | `m_mitglied.id` | NO ACTION | `FK_m_u_m_gl` |
| `x_fa` | `mitglied_id` | `m_mitglied.id` | **CASCADE** | (vom System vergeben) |
| `x_fa` | `yfun_id` | `d_yfun.id` | NO ACTION | (vom System vergeben) |
| `x_gruppe_mitglied` | `mitglied_id` | `m_mitglied.id` | **CASCADE** | (vom System vergeben) |
| `x_gruppe_mitglied` | `gruppe_id` | `d_gruppe.id` | NO ACTION | (vom System vergeben) |
| `x_mitglied_adresse` | `mitglied_id` | `m_mitglied.id` | NO ACTION | `fk_x_gl_adresse_gl` |
| `x_mitglied_adresse` | `adresse_id` | `m_adresse.adresse_id` | NO ACTION | `fk_x_gl_adresse_adresse` |
| `x_objekt_gruppe` | `objekt_id` | `m_objekt.objekt_id` | **CASCADE** | `fk_x_objekt_gruppe_objekt` |
| `x_objekt_gruppe` | `ygrp_id` | `d_gruppe.id` | NO ACTION | `fk_x_objekt_gruppe_ygrp` |
| `x_role_perm` | `perm_id` | `d_perm.id` | **CASCADE** | `FK_x_rp_perm` |
| `x_role_perm` | `role_id` | `d_role.id` | **CASCADE** | `FK_x_rp_role` |
| `x_user_role` | `role_id` | `d_role.id` | **CASCADE** | `FK_x_ur_role` |
| `x_user_role` | `user_id` | `m_user.id` | **CASCADE** | `FK_x_ur_user` |

### Löschverhalten

- Löschen einer Zeile in `d_perm` löscht automatisch Zeilen in: `x_role_perm`.
- Löschen einer Zeile in `d_role` löscht automatisch Zeilen in: `x_role_perm`, `x_user_role`.
- Löschen einer Zeile in `m_mitglied` löscht automatisch Zeilen in: `f_soll`, `m_jump`, `m_mark`, `x_fa`, `x_gruppe_mitglied`.
- Löschen einer Zeile in `m_objekt` löscht automatisch Zeilen in: `x_objekt_gruppe`.
- Löschen einer Zeile in `m_user` löscht automatisch Zeilen in: `x_user_role`.
- Alle übrigen Fremdschlüssel sind `NO ACTION`: Das Löschen der Zielzeile **scheitert**, solange abhängige Zeilen bestehen.
- Diese `NO ACTION`-Verweise zeigen auf Tabellen, die selbst an einer CASCADE-Kette beteiligt sind, und verhindern das Löschen der Zielzeile, solange Verweise bestehen: `f_ist.soll_id` → `f_soll`, `m_jump.u_id` → `m_user`, `m_mark.u_id` → `m_user`, `m_user.mitglied_id` → `m_mitglied`, `x_mitglied_adresse.mitglied_id` → `m_mitglied`.

---

## 5 Datenbank-Objekte

| Objekt | Typ | Bezug | Funktion |
|---|---|---|---|
| `tr_f_ist_auto_close` | Trigger (AFTER INSERT, UPDATE) | `f_ist` | Setzt `f_soll.erledigt` auf 1, wenn die Summe der zugeordneten Zahlungen den Soll-Betrag erreicht, sonst auf 0. Läuft nur bei INSERT und UPDATE auf `f_ist`, nicht beim Löschen einer Zahlung. |
| `tr_m_adresse_immutable` | Trigger (INSTEAD OF UPDATE) | `m_adresse` | Lehnt jedes UPDATE auf `m_adresse` ab, außer `CONTEXT_INFO` ist auf `adresse_korrektur` gesetzt (das tut `sp_adresse_korrigieren`). |
| `tr_x_mitglied_adresse_no_overlap` | Trigger (AFTER INSERT, UPDATE) | `x_mitglied_adresse` | Verhindert sich überlappende Gültigkeitszeiträume je Mitglied in `x_mitglied_adresse` (halb-offenes Intervall: `gueltig_bis` ist der erste Tag ohne Gültigkeit) |
| `sp_adresse_korrigieren` | Stored Procedure | `@adresse_id int`, `@strasse nvarchar(100)`, `@hausnummer nvarchar(10)`, `@adresszusatz nvarchar(100)`, `@ort_id int` | Einzig zulässiger Weg, eine Zeile in `m_adresse` nachträglich zu ändern; setzt `CONTEXT_INFO` für den Trigger und setzt es danach zurück. |
| `sp_multiplier_soll` | Stored Procedure | `@ygrp_id int`, `@jahr int`, `@zweck nvarchar(100)`, `@batch_id uniqueidentifier` | Massenanlage von Gebühren (`f_soll`) für alle Mitglieder einer Gruppe mit Status Aktiv oder Ehrenmitglied (`status_id` 1 und 3); Fälligkeit 1. März des Jahres; liefert die BatchId. |
| `v_user_perms` | Sicht | `d_perm`, `d_role`, `m_user`, `x_role_perm`, `x_user_role` | Effektive Berechtigungen je Benutzer (Benutzer × Rolle × Berechtigung). |

---

## 6 Enums (C#-seitig, Werte = Datenbank-IDs)

- `Anrede` (`MemberEnums.cs`): Herr=1, Frau=2, Divers=3, Familie=4, Firma=5
- `MemberStatus` (`MemberEnums.cs`): Aktiv=1, Passiv=2, Ehrenmitglied=3, Gekuendigt=4, InPruefung=5, Ausgetreten=6
- `Zahlungsart` (`Enums.cs`): Ueberweisung=1, Bar=2, Lastschrift=3, Paypal=4

---

## 7 Indizes

Außer den Primärschlüsseln und den unter Abschnitt 2 je Tabelle genannten UNIQUE-Constraints und Indizes enthält das Datenbankprojekt **keine weiteren Indizes**. Insbesondere gibt es keinen Index auf `m_mitglied.status_id` (Filter `status_id <> 6`) und keinen auf `f_soll.erledigt` (Filter `erledigt = 0`).

---

## 8 Änderungen gegenüber der Vorgängerfassung (Stand 2026-04-01)

- Neuaufbau aus dem Datenbankprojekt statt Handpflege: alle 28 Tabellen (vorher 21), 30 Fremdschlüssel (vorher 22).
- Namen: 13 Tabellen und 36 Spalten wurden umbenannt; die Zuordnung alt → neu steht in Abschnitt 3.
- Neu: Adress-Tabellen (`d_land`, `d_ort`, `m_adresse`, `x_mitglied_adresse`) und Vereinsobjekte (`d_objekttyp`, `m_objekt`, `x_objekt_gruppe`) mit Trigger und Prozedur für unveränderliche Adressen und Überlappungsschutz.
- Neu je Tabelle: Zugriff im Code, C#-Klasse und C#-Property je Spalte (wo der Code die Spalte per Namen liest), Enums direkt aus dem Code.
- Korrigiert: Der frühere Hinweis „Zahlungen bleiben als Waisen“ trifft nicht zu. `f_ist.soll_id` ist `NO ACTION`; das Löschen eines Mitglieds mit Zahlungen scheitert (Abschnitt 4). Hergeleitet aus der DDL.
- Korrigiert: `tr_f_ist_auto_close` setzt `erledigt` auch auf 0 (nicht nur auf 1) und läuft nicht beim Löschen einer Zahlung.
- Korrigiert: `x_role_perm.perm_id` → `d_perm` und `x_user_role.role_id` → `d_role` sind `CASCADE` (Vorgängerfassung: `NO ACTION`); so steht es seit dem ersten Stand des Datenbankprojekts in der DDL.
- Präzisiert: `f_soll.erledigt` wird beim Anlegen mit 0 geschrieben und nur bei Zahlungsänderungen neu berechnet; eine Änderung des Soll-Betrags berechnet es nicht neu (Abschnitt 2, `f_soll`).
- Unverändert: Die in der Vorgängerfassung als „geplant“ geführten Indizes auf `status_id` und `erledigt` gibt es weiterhin nicht (Abschnitt 7).
- Entfallen: Abschnitt „Noch nicht im C# implementiert“; ersetzt durch „Zugriff im Code“ je Tabelle.
- Entfallen: Angabe von Server und Datenbankname im Kopf.

