# yam2 — Adress-Infrastruktur Design v3

**Stand:** 2026-04-20
**Autor:** Ovaya
**Review:** G.B.
**Status:** Vorschlag zur Genehmigung
**Begleitdateien:** `adress-design-v3-02.sql`, `db-projekt-setup-03.md`

---

## 1. Kontext

Aufgabe aus Teams-Chat (2026-04-20): Adress-Design mit Anwendungsfällen und Logik für verschiedene Zustände, vor Implementation. Voraussetzung: DB-Projekt (separates Dokument).

## 2. Anwendungsfälle

| Nr | Fall | Essenz |
|---|---|---|
| UC-1 | Mitglied-Standardadresse | Eine aktive Adresse pro Mitglied — für Etikett, Verzeichnis, Mahnbrief |
| UC-2 | Adresse ändert sich ab Datum X | Umzug mit Historisierung, Wirksamkeit ab Datum |
| UC-3 | Haushalt — mehrere Mitglieder gleiche Adresse | Familie pflegt eine Adresse, keine Redundanz |
| UC-4 | Vereinssitz | Offizielle Adresse des Vereins (laut Register) |
| UC-5 | Vereinsheim | Eigenes Objekt des Vereins mit Adresse + Name |
| UC-6 | Sportstätte | Ort für Aktivität (Beschreibung: "Handball in Sporthalle …") |
| UC-7 | Haushalts-Umzug | Familie zieht gemeinsam — ein Arbeitsschritt für alle |
| UC-8 | Auszug aus Haushalt | Einer zieht aus, andere bleiben an alter Adresse |
| UC-9 | Internationale Mitglieder | AT/CH möglich, PLZ variable Länge |
| UC-10 | DSGVO-Auskunft | Vollständige Adress-Historie abrufbar |
| UC-11 | DSGVO-Löschung | Personendaten anonymisieren, Adresse selbst bleibt |
| UC-12 | Mahnbrief historisch | Adresse zum Fälligkeitsdatum verwenden |
| UC-13 | Austritt | Adresse bleibt aktiv — Austritt ≠ Umzug |

## 3. Logik-Entscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Mehrere Adressen parallel | Nein — genau eine aktive pro Mitglied | Komplexität ohne Vereins-Nutzen |
| Historisierung-Ort | Separate Zuordnungstabelle `x_gl_adresse` | Mitglied-Stammdaten bleiben sauber |
| Adress-Datensatz | **Immutable** (per Trigger) | Historie sonst inkonsistent |
| Tippfehler-Korrektur | Eigene SP `sp_adresse_korrigieren` | Einziger legitimer Änderungs-Pfad |
| Umzug vs. Korrektur | Zwei getrennte Fach-Operationen | Semantische Klarheit |
| Haushalt-Konzept | Implizit über geteilte `adresse_id` | Kein eigener Typ nötig |
| Haushalts-Umzug | Eigene Operation `MoveHousehold` | Atomar für alle betroffenen Mitglieder |
| Austritt | Ändert Adresse **nicht** | Ex-Mitglied wohnt weiter dort |
| DSGVO-Löschung | Anonymisieren (AO §147 Aufbewahrung) | Gesetzeskonform |
| Land-Support | `d_land` Lookup mit PLZ-Regex | Internationale Mitglieder möglich |
| PLZ-Feld | `VARCHAR(10)` | DE 5 / AT 4 / CH 4 / GB bis 8 alphanum. |
| Hausnummer | NULL zulässig mit CHECK-Constraint | Postfach, "an der alten Mühle" |
| Vereinsheim | Eigene Tabelle `m_vereinsheim` | Erweiterbar (Kapazität, Hausmeister …) |
| Sportstätten-Buchung | **Nicht** in diesem Design | Separates Modul — auf Anforderung |

## 4. DB-Design

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

### 4.3 SQL

Vollständige DDL: siehe `adress-design-v3.sql` (neue Tabellen, Trigger, Indizes, minimale Seed-Daten).

### 4.4 Zentrale Konstrukte

- **Filter-Unique-Index** `uq_x_gl_adresse_aktiv WHERE gueltig_bis IS NULL` — erzwingt max. eine aktive Adresse pro Mitglied
- **Immutable-Trigger** `tr_m_adresse_immutable` — UPDATE auf `m_adresse` nur via SP mit CONTEXT_INFO
- **CHECK** `ck_m_adresse_mindestangabe` — Hausnummer ODER Adresszusatz gesetzt
- **Dedupe-Index** `uq_m_adresse_physisch` — identische Adressen nur einmal gespeichert

## 5. Migrations-Pfad

Existierendes `m_gl` enthält `str`, `plz`, `ort` — diese Spalten bleiben während Übergangsphase bestehen.

| Phase | Aktion | Breaking? |
|---|---|---|
| 1 | Neue Tabellen anlegen | Nein |
| 2 | Migrations-Skript: vorhandene `m_gl`-Adressdaten in `m_adresse` + `x_gl_adresse` überführen | Nein |
| 3 | Repository neu: Schreibzugriff auf neue Tabellen, Leseabfrage fällt bei leerem Ergebnis auf alte Spalten zurück | Nein |
| 4 | UI-Umstellung auf neue Struktur | Nein |
| 5 | Stichtag: alte Spalten `DROP COLUMN` | **Ja** — nur mit DB-Projekt machbar |

## 6. Offene Entscheidungen (Review)

Bitte um Stellungnahme vor Implementation:

| # | Entscheidung | Vorschlag Ovaya |
|---|---|---|
| 1 | `m_gl` → `m_mitglied` umbenennen (langfristig, mit allen FK-Spalten `gl_id → mitglied_id`) | Ja — in separater Migration nach Adress-Abschluss |
| 2 | Bestehende `m_gl`-Kürzel-Spalten (`vn`, `nn`, `tel`, `mail`, `geb`) jetzt ausschreiben oder später | Später — gemeinsam mit Punkt 1 |
| 3 | `d_ort` komplett vorbefüllen (~8000 DE-PLZ) oder On-Demand beim Speichern anlegen | **On-Demand** — wächst organisch, weniger Pflege |
| 4 | PLZ-Validierung per `d_land.plz_regex` in UI-Schicht sofort aktiv | Ja — verhindert Müll-Daten |
| 5 | DB-Projekt vor Adress-Implementation aufsetzen | **Ja** — siehe `db-projekt-setup.md` |
| 6 | DSGVO-Anonymisierung: Felder auf NULL oder Platzhalter ("anonymisiert") | Platzhalter — bessere Diagnose in Listen |
| 7 | Vereinsheim als eigene Tabelle `m_vereinsheim` (statt zwei Spalten in `d_ygrp`) | Ja — zukunftsfähig |

## 7. Voraussetzung

DB-Projekt muss vor Implementation existieren. Ohne DB-Projekt vergrößert sich der Schema-Drift mit jedem neuen Objekt. Planung: `db-projekt-setup.md`.

## 8. Nicht-Ziele (bewusst weggelassen)

- Sportstätten-Buchungen / Raumbelegung
- Adress-Zugriffs-Audit (DSGVO Art. 30) — Folge-Modul
- Google-Maps-Integration
- Externe Adress-Validierungs-API (Deutsche Post)
- Mehrere parallele Adressen pro Mitglied
- Vereinssitz-Historisierung

Jedes Thema ist separat beauftragbar, keine Abhängigkeit zum Grunddesign.
