# Arbeitslog — 04.05.2026

**Projekt:** yam2 | **Bearbeiter:** Azubi | **Ausbilder:** Gino

---

## Erledigt

| # | Aufgabe |
|---|---|
| 1 | Projektstatus-Analyse (Chats ab 31.03.) + Vorgehensplan erarbeitet |
| 2 | SSDT-Projekt `yam2.Database` angelegt, Schema via SQL-Skript importiert (92 Anweisungen, alle [SCHEMA]-Tabellen/Views/SPs/Trigger) |
| 3 | `adress-design.md` — Section 6 auf aktuellen SSDT-Stand aktualisiert |

---

## Hinweise

**⚠️ VS 2017 → DB-Server: Verbindungsproblem im SSDT-Import-Dialog**
- Direkte Live-Verbindung schlug fehl (Fehler 26 / fehlende Windows-Auth-Option)
- Workaround: Schema-Export über SSMS → Import als Skript in SSDT ✅
- Verbindung selbst ist OK (PowerShell-Test erfolgreich)

**ℹ️ DSP-Mismatch**
- Projekt zielt auf SQL 2016, Live-DB ist SQL 2022
- Kein praktisches Problem für yam2 (keine 2022-spezifische Syntax in Verwendung)

**ℹ️ `dbo`-Schema enthält Lernprojekt-Altlasten**
- EF-Tabellen, Übungstabellen — nicht Teil von yam2
- Bei Schema-Compare ignorieren

---

## Nächste Schritte

1. SSDT Build → Fehler beheben
2. Adress-DDL (6 Tabellen) ins Projekt
3. `d_ygrp` um `vereinssitz_adresse_id` ergänzen
4. Git-Commit DB-Projekt
5. `GroupsViewModel` (offen seit 13.04.)
6. Gino-Freigabe `adress-design.md` (7 offene Entscheidungen)
