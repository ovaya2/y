# yam2 — DB-Projekt-Setup (Skizze)

**Stand:** 2026-04-20
**Zweck:** Plan für Einführung eines SQL Server Database Projects (SSDT)
**Auslöser:** Ausbilder-Hinweis — Schema-Drift sichtbar, DB-Projekt fehlt

---

## 1. Problem

Aktuell: DB-Schema (`[yam3]` auf `SauerSQL2.ovaya_test`) existiert nur auf dem Server. Dokumentation in `docs/schema.md` muss manuell nachgezogen werden — ist bereits gedriftet.

**Risiken:**
- Schema-Änderungen nicht nachvollziehbar (kein Git-History für DDL)
- Kein automatisches Deployment / kein Rollback
- Teammitglieder / Migration auf neue Umgebung umständlich
- Jede Strukturänderung gefährdet vorhandene Daten

## 2. Lösung: SQL Server Database Project (SSDT)

Visual-Studio-Projekttyp, der das gesamte DB-Schema als Code behandelt. Build erzeugt eine **DACPAC** (Deployment-Artefakt), deploybar gegen jede Zielumgebung.

## 3. Struktur

```
yam2.sln
├── yam2/                        # WPF-App (bestehend)
└── yam2.Database/               # NEU: DB-Projekt
    ├── yam3/
    │   ├── Tables/
    │   │   ├── m_gl.sql
    │   │   ├── m_adresse.sql
    │   │   ├── x_gl_adresse.sql
    │   │   └── ... (alle Tabellen pro Datei)
    │   ├── Views/
    │   ├── StoredProcedures/
    │   ├── Triggers/
    │   │   └── tr_f_ist_auto_close.sql
    │   └── Security/            # Schema, Rollen
    ├── Scripts/
    │   ├── PreDeployment.sql    # z.B. Backup-Hinweis
    │   └── PostDeployment.sql   # Seed-Daten (Lookups, RBAC)
    └── yam2.Database.sqlproj
```

## 4. Einführungs-Schritte

| # | Schritt | Aufwand |
|---|---|---|
| 1 | SSDT-Projekt in Solution anlegen | 10 min |
| 2 | Schema-Import aus `SauerSQL2.ovaya_test.yam3` (Schema Compare oder Import Wizard) | 30 min |
| 3 | Build → sicherstellen dass DACPAC erzeugt wird, keine Validierungsfehler | 1 h (meist Reference-Fehler beheben) |
| 4 | Post-Deployment-Skript für Seed-Daten (d_perm, d_role, d_anr, d_sta, ...) | 1–2 h |
| 5 | Ersten Schema-Compare gegen Live-DB → Drift dokumentieren und gleichziehen | 2 h |
| 6 | In Git committen, ab diesem Punkt: alle Schema-Änderungen nur noch über Projekt | — |

**Gesamt:** ~1 Arbeitstag initial.

## 5. Workflow ab Einführung

**Neue Tabelle / Änderung:**
1. Änderung in `yam2.Database/yam3/...` als SQL-Datei
2. Build → DACPAC wird erzeugt
3. Git-Commit
4. Deployment via *Schema Compare* oder `sqlpackage.exe /Publish`
5. Rollback: alten DACPAC-Stand erneut deployen

**Breaking Changes** (Umbenennung, DROP COLUMN):
- Pre-/Post-Deployment-Skripte handhaben Daten-Migration
- DACPAC erkennt Änderungen und generiert `ALTER`/Daten-Skripte

## 6. Abhängigkeit für die Adress-Infrastruktur

Die Adress-Infrastruktur bringt 6 neue Tabellen + Änderungen an `d_ygrp`. **Ohne DB-Projekt** vergrößert sich der Drift weiter. **Mit DB-Projekt** sind alle neuen Tabellen von Anfang an versioniert.

**Empfehlung:** DB-Projekt **vor** der Adress-Implementierung aufsetzen — Reihenfolge:
1. DB-Projekt anlegen + Live-Schema importieren
2. Adress-Design genehmigen lassen
3. Neue Tabellen direkt im DB-Projekt anlegen
4. Deployment erstmals regulär via DACPAC

## 7. Offene Punkte für Review

- **Namenskonvention Dateipfade** — `Tables/m_gl.sql` oder `Tables/Master/m_gl.sql` (thematisch gruppiert)?
- **Pre/Post-Deployment-Scope** — nur Seed-Daten oder auch Test-Daten?
- **CI-Integration** — Build-Pipeline mit DACPAC-Produktion bereits jetzt oder später?
