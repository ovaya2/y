# docs/schema.md — yam2 DB-Schema

Schema: `[yam3]` | DB: `ovaya_test` | Server: `SauerSQL2` | Stand: 2026-04-01
Verifiziert: `ova--dbinfo-v1--out-1.rpt` (2026-03-10) + RBAC-Erweiterung im Code

---

## Tabellenübersicht

| Präfix | Bedeutung | Tabellen |
|---|---|---|
| `d_` | Lookup/Dimensions | d_anr, d_perm, d_role, d_sta, d_ybart, d_yfun, d_ygrp, d_ykto, d_ysolltyp, d_zart |
| `f_` | Faktentabellen (Bewegungsdaten) | f_ist, f_soll |
| `m_` | Mastertabellen (Stammdaten) | m_gl, m_jump, m_mark, m_u |
| `t_` | Technische Tabellen | t_reg |
| `x_` | Zuordnungstabellen | x_fa, x_gm, x_rp, x_ur |

---

## Primärtabellen mit C#-Mapping

### `[yam3].[m_gl]` → C# `Member`

| Spalte | Typ | Null | Default | C#-Property |
|---|---|---|---|---|
| `id` | int IDENTITY | N | — | `Id` |
| `gl_nr` | nvarchar(20) | N | — | `Mitgliedsnummer` — UNIQUE |
| `anr_id` | int | N | 1 | `Anrede` (→ `d_anr`) |
| `vn` | nvarchar(50) | N | — | `Vorname` |
| `nn` | nvarchar(50) | N | — | `Nachname` |
| `geb` | date | **Y** | — | `Geburtstag` (DateTime?) |
| `mail` | nvarchar(100) | **Y** | — | `Email` |
| `tel` | nvarchar(50) | **Y** | — | `Telefon` |
| `str` | nvarchar(100) | **Y** | — | `Strasse` |
| `plz` | nvarchar(10) | **Y** | — | `PLZ` |
| `ort` | nvarchar(100) | **Y** | — | `Ort` |
| `iban` | nvarchar(34) | **Y** | — | `IBAN` |
| `bic` | nvarchar(11) | **Y** | — | `BIC` |
| `sepa_ref` | nvarchar(35) | **Y** | — | `SepaReferenz` |
| `sepa_datum` | date | **Y** | — | `SepaDatum` (DateTime?) |
| `sta_id` | int | N | 1 | `Status` (→ `d_sta`, Enum `MemberStatus`) |
| `ybart_id` | int | N | 1 | `BeitragId` (→ `d_ybart`) |
| `eintritt` | date | N | getdate() | `Eintrittsdatum` |
| `austritt` | date | **Y** | — | `Austrittsdatum` (DateTime?) |
| `dsgvo_dat` | bit | N | 0 | `DsgvoOk` |
| `dsgvo_foto` | bit | N | 0 | `DsgvoFoto` |
| `erstellt_am` | datetime | **Y** | getdate() | ⚠ nicht im C#-Model |
| `geaendert_am` | datetime | **Y** | getdate() | ⚠ nicht im C#-Model — via `SET geaendert_am = GETDATE()` bei UPDATE |

Computed (C# only): `VollerName`, `IstAktiv`, `StatusText`

> ⚠ `zart_id` existiert NICHT in `m_gl` — Property `ZahlungsartId` in v3.4 entfernt.

---

### `[yam3].[f_soll]` → C# `Fee`

| Spalte | Typ | Null | Default | C#-Property |
|---|---|---|---|---|
| `id` | int IDENTITY | N | — | `Id` |
| `gl_id` | int | N | — | `MemberId` (FK → `m_gl.id`, CASCADE) |
| `ybart_id` | int | N | — | `YbartId` (FK → `d_ybart.id`) |
| `ysolltyp_id` | int | N | 1 | `YsolltypId` (FK → `d_ysolltyp.id`) |
| `jahr` | int | N | — | `Year` |
| `betrag` | decimal(8,2) | N | — | `Amount` |
| `zweck` | nvarchar(100) | N | — | `Purpose` |
| `faellig` | date | N | — | `DueDate` |
| `erledigt` | bit | N | 0 | `IsDone` — **NUR Trigger `tr_f_ist_auto_close`!** |
| `batch_id` | uniqueidentifier | **Y** | — | `BatchId` (Guid?) |

Computed (C# only): `IsOverdue`, `RemainingAmount`, `DisplayLabel`
Aus JOIN: `PaidAmount` = `COALESCE(SUM(f_ist.betrag), 0)`

---

### `[yam3].[f_ist]` → C# `Payment`

| Spalte | Typ | Null | Default | C#-Property |
|---|---|---|---|---|
| `id` | int IDENTITY | N | — | `Id` |
| `soll_id` | int | **Y** | — | `SollId` (FK → `f_soll.id`, freie Buchung möglich) |
| `ykto_id` | int | N | 1 | `YktoId` (FK → `d_ykto.id`) |
| `zart_id` | int | N | 1 | `ZartId` (FK → `d_zart.id`) |
| `betrag` | decimal(8,2) | N | — | `Amount` |
| `datum` | date | N | getdate() | `Date` |
| `text` | nvarchar(100) | **Y** | — | `Text` |
| `batch_id` | uniqueidentifier | **Y** | — | `BatchId` (Guid?) |

---

### `[yam3].[m_u]` → C# `AppUser`

| Spalte | Typ | Null | Default | C#-Property |
|---|---|---|---|---|
| `id` | int IDENTITY | N | — | `Id` |
| `gl_id` | int | **Y** | — | `GlId` (int?, FK → `m_gl.id`) |
| `win_user` | nvarchar(100) | N | — | `WinUser` — UNIQUE |
| `is_admin` | bit | N | 0 | `IsAdmin` |
| `letzter_login` | datetime | **Y** | — | `LetzterLogin` (DateTime?) |

Aus JOIN mit `m_gl`: `MemberName` (vn + ' ' + nn)
Computed: `DisplayName`, `IsSuperadmin`, `HasPermission(permKey)`, `EffectivePermissions`

---

## Lookup-Tabellen (`d_`)

| Tabelle | C#-Rückgabe | Besonderheit |
|---|---|---|
| `d_anr` — `id, bez(20)` | FK-Lookup | Enum `Anrede` (Herr=1, Frau=2, Divers=3, Familie=4, Firma=5) |
| `d_sta` — `id, bez(50)` | FK-Lookup | Enum `MemberStatus` (Aktiv=1..Ausgetreten=6) |
| `d_ybart` — `id, bez(50), std_betrag decimal(8,2)` | `LookupItem` | **`std_betrag`** für `CreateDefaultFeeAsync` |
| `d_ysolltyp` — `id, bez(50)` | `LookupItem` | Soll-Typen |
| `d_ykto` — `id, bez(50), iban(34)?` | `LookupItem` | Vereinskonten |
| `d_zart` — `id, bez(30)` | `LookupItem` | Enum `Zahlungsart` (Ueberweisung=1..Paypal=4) |

---

## RBAC-Tabellen (neu, im Code implementiert)

### `[yam3].[d_role]` → C# `Role`

| Spalte | Typ | Null | C#-Property |
|---|---|---|---|
| `id` | int PK | N | `Id` |
| `bez` | nvarchar(50) | N | `Bezeichnung` — UNIQUE |
| `beschreibung` | nvarchar(200) | N | `Beschreibung` |
| `is_superadmin` | bit | N | `IsSuperadmin` — bypassed alle Checks |
| `is_system` | bit | N | `IsSystem` — nicht löschbar |

### `[yam3].[d_perm]` → C# `Permission`

| Spalte | Typ | Null | C#-Property |
|---|---|---|---|
| `id` | int PK | N | `Id` |
| `perm_key` | nvarchar(50) | N | `PermKey` — UNIQUE, Format: `"modul.aktion"` |
| `modul` | nvarchar(30) | N | `Modul` |
| `aktion` | nvarchar(20) | N | `Aktion` |
| `bez` | nvarchar(100) | N | `Bezeichnung` |

### `[yam3].[x_ur]` — User ↔ Rolle

| Spalte | Typ | Null |
|---|---|---|
| `u_id` | int PK (Teil), FK → `m_u.id` ON DELETE CASCADE | N |
| `role_id` | int PK (Teil), FK → `d_role.id` | N |
| `zugewiesen_am` | datetime | N |

### `[yam3].[x_rp]` — Rolle ↔ Permission

| Spalte | Typ | Null |
|---|---|---|
| `role_id` | int PK (Teil), FK → `d_role.id` ON DELETE CASCADE | N |
| `perm_id` | int PK (Teil), FK → `d_perm.id` | N |

---

## Noch nicht im C# implementiert

| Tabelle | Struktur | Zweck |
|---|---|---|
| `m_jump` | `u_id→m_u, gl_id→m_gl(CASCADE), besucht_am` | Besuchshistorie |
| `m_mark` | `u_id→m_u, gl_id→m_gl(CASCADE), mark_char char(1)` | Markierungen/Tags |
| `t_reg` | `reg_name char(1) PK, payload nvarchar(MAX)` | App-Einstellungen Key-Value |
| `x_gm` | PK(`gl_id`,`ygrp_id`), `seit` | Mitglied ↔ Gruppe |
| `x_fa` | PK(`gl_id`,`yfun_id`), `wahl` | Mitglied ↔ Funktion |
| `d_ygrp` | `id, bez(50)` | Gruppen/Abteilungen |
| `d_yfun` | `id, bez(50)` | Funktionen/Ämter |

---

## Foreign Keys (vollständig)

| FK | Tabelle.Spalte → Ref | ON DELETE |
|---|---|---|
| `FK_m_gl_d_anr` | `m_gl.anr_id → d_anr.id` | NO ACTION |
| `FK_m_gl_d_sta` | `m_gl.sta_id → d_sta.id` | NO ACTION |
| `FK_m_gl_d_ybart` | `m_gl.ybart_id → d_ybart.id` | NO ACTION |
| `FK_f_soll_m_gl` | `f_soll.gl_id → m_gl.id` | **CASCADE** |
| `FK_f_soll_d_ybart` | `f_soll.ybart_id → d_ybart.id` | NO ACTION |
| `FK_f_soll_d_ysolltyp` | `f_soll.ysolltyp_id → d_ysolltyp.id` | NO ACTION |
| `FK_f_ist_f_soll` | `f_ist.soll_id → f_soll.id` | NO ACTION |
| `FK_f_ist_d_ykto` | `f_ist.ykto_id → d_ykto.id` | NO ACTION |
| `FK_f_ist_d_zart` | `f_ist.zart_id → d_zart.id` | NO ACTION |
| `FK_m_u_m_gl` | `m_u.gl_id → m_gl.id` | NO ACTION |
| `FK_jump_gl` | `m_jump.gl_id → m_gl.id` | **CASCADE** |
| `FK_jump_u` | `m_jump.u_id → m_u.id` | NO ACTION |
| `FK_mark_gl` | `m_mark.gl_id → m_gl.id` | **CASCADE** |
| `FK_mark_u` | `m_mark.u_id → m_u.id` | NO ACTION |
| `x_fa → m_gl` | `x_fa.gl_id → m_gl.id` | **CASCADE** |
| `x_fa → d_yfun` | `x_fa.yfun_id → d_yfun.id` | NO ACTION |
| `x_gm → m_gl` | `x_gm.gl_id → m_gl.id` | **CASCADE** |
| `x_gm → d_ygrp` | `x_gm.ygrp_id → d_ygrp.id` | NO ACTION |
| `x_ur → m_u` | `x_ur.u_id → m_u.id` | **CASCADE** |
| `x_ur → d_role` | `x_ur.role_id → d_role.id` | NO ACTION |
| `x_rp → d_role` | `x_rp.role_id → d_role.id` | **CASCADE** |
| `x_rp → d_perm` | `x_rp.perm_id → d_perm.id` | NO ACTION |

> ⚠ CASCADE auf `m_gl`: Löschen eines Members löscht `f_soll`, `m_jump`, `m_mark`, `x_fa`, `x_gm`.
> `f_ist` hat **kein** CASCADE — Zahlungen bleiben als Waisen (Kassenprüfung!).

---

## Enums (C#-seitig, Werte = DB-IDs)

```csharp
enum MemberStatus { Aktiv=1, Passiv=2, Ehrenmitglied=3, Gekuendigt=4, InPruefung=5, Ausgetreten=6 }
enum Anrede       { Herr=1, Frau=2, Divers=3, Familie=4, Firma=5 }
enum Zahlungsart  { Ueberweisung=1, Bar=2, Lastschrift=3, Paypal=4 }
```

---

## DB-Objekte (Stored Procedure + Trigger)

| Objekt | Typ | Funktion |
|---|---|---|
| `[yam3].[sp_multiplier_soll]` | Stored Procedure | Massenanlage `f_soll` via BatchId; Parameter: `@ygrp_id, @jahr, @zweck, @batch_id` |
| `tr_f_ist_auto_close` | Trigger (AFTER INSERT, UPDATE auf `f_ist`) | Setzt `f_soll.erledigt=1` wenn `SUM(f_ist.betrag) >= f_soll.betrag` |

---

## Indizes (verifiziert im DB-Report 2026-03-10)

Vorhandene Indizes: nur PKs (CLUSTERED auf `id`) + UNIQUE auf `m_gl.gl_nr` und `m_u.win_user`.

**Fehlende Indizes (geplant):**
```sql
-- Soft-Delete-Filter: WHERE sta_id <> 6
CREATE INDEX IX_m_gl_sta_id ON [yam3].[m_gl](sta_id);

-- Offene-Forderungen-Filter: WHERE erledigt = 0
CREATE INDEX IX_f_soll_erledigt ON [yam3].[f_soll](erledigt, gl_id);
```
