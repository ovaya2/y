<!-- ENTSCHEIDUNGEN.md — v1.3.2 -->
<!-- v1.3.2: E-010 von Ovaya bestätigt (Rollout-Reihenfolge Sportstätten wie vorgeschlagen), Status `entschieden` -->
<!-- v1.3.0: neu E-011 (Name des Überlappungs-Triggers für Adressen, O-5) -->
<!-- v1.2.0: E-001, E-002, E-004 auf `getestet` (Belege SP1–SP4, W4.8), neu E-009 (Namen Objekt-Modell) und E-010 (Rollout-Reihenfolge) -->
<!-- v1.1.0: Status `vorgeschlagen` für Klasse C, Verweise auf s9-arbeitsstand.md, Datum E-004 (05.10.), Commit-Format, Umfang E-004 nach [PU] §3 -->
# yam2 — Entscheidungsprotokoll

Regeln: `s9-arbeitsstand.md` §3 (Klassen A/B/C) und §0 (Änderungsprinzipien). Ein Eintrag je Entscheidung; eine Änderung ersetzt den Eintrag vollständig und erhöht die Version dieser Datei.
Status: entschieden | entwickelt | getestet | bereit | freigegeben | verworfen; Klasse C: `vorgeschlagen` (Ginos Entscheidung).
Commits zu einer Entscheidung tragen ihre ID in der Nachricht, z. B. `[E-004]`.
„offen“ = in den Planungsdateien nicht belegt, Ovaya ergänzt (mit Datum).
Maskiert: `[DB-SERVER]`, `[DB-NAME]`, `[USER]`.

| ID | Thema | Kl. | Status |
|---|---|---|---|
| E-001 | Vereinssitz | B | **getestet** (Probe-DB) |
| E-002 | Objekt-Beschreibung | A | **getestet** (Probe-DB) |
| E-003 | Whitespace-Normalisierung | A | entschieden (vorläufig) |
| E-004 | `m_gl` → `m_mitglied` | B | **getestet** (Probe-DB) |
| E-005 | Rolle „Leser“ | C | vorgeschlagen |
| E-006 | Rollen-Zuweisung in der UI | C | vorgeschlagen |
| E-007 | Soll-Typ-Name in der Gebührenliste | A | entschieden (vorläufig) |
| E-008 | Indizes (Ginos Hinweis 8) | B | entschieden (vorläufig) |
| E-009 | Namen im Objekt-Modell (Abweichung von v4.1) | A | **getestet** (Probe-DB) |
| E-010 | Rollout-Reihenfolge Sportstätten | B | entschieden |
| E-011 | Name des Überlappungs-Triggers (Adressen) | A | **getestet** (Probe-DB) |

## E-001 — Vereinssitz        [Klasse B · Status: getestet]
- **Gino-Bezug:** Adress-Design §7 #7 (V4: Vorschlag stand nur in der Tabelle, nicht im DDL); Ginos Rückmeldung 06.05. (Vereinsheim/Sportstätte zusammenführen)
- **Entscheidung:** Flag `ist_sitz` an `m_objekt` + Filter-Unique-Index `uq_m_objekt_sitz` (`WHERE ist_sitz = 1`): höchstens ein Sitz pro Datenbank.
- **Begründung:** Die Datenbank erzwingt „ein Sitz“ selbst, ohne App-Logik. Annahme: eine Datenbank = ein Verein (Mehrmandanten sind kein Ziel, Adress-Design §8).
- **Nächste Alternative:** eigener Objekttyp „Vereinssitz“ (`d_objekttyp` id 5) · Wechselaufwand: 1 Seed-Zeile, Index und Spalte entfernen (vor dem ersten Rollout auf `[DB-NAME]` nur Projektdateien) · Auslöser: Gino will den Sitz als eigenes Objekt oder mehrere Vereine pro DB
- **Umsetzung/Test:** Branch `feature/sportstaetten-objekt`, Commit `13f640d` [SP2] (`m_objekt.sql` v1.0.0); Spike `896b0cf` [SP1] T05 (erster Sitz OK) und T06 (zweiter Sitz FEHLER 2601) ✓; Probe-DB veröffentlicht (SP4, 05.10.)
- **Rückweg:** Code `git revert 13f640d`; Probe-DB `DROP TABLE` in der Reihenfolge `x_objekt_gruppe`, `m_objekt`, `d_objekttyp`
- **Review bis:** Ginos Freigabe der Adress-Konzepte (Datum offen) · Vertrauen: hoch (Constraint-Test T05/T06)

## E-002 — Objekt-Beschreibung        [Klasse A · Status: getestet]
- **Gino-Bezug:** Adress-Design §7 #8; Nachricht 07.05., Punkt 8
- **Entscheidung:** Freitext in `x_objekt_gruppe.beschreibung` (`NVARCHAR(200)`, z. B. „Handball jeden Dienstag 18-20 Uhr“).
- **Begründung:** Strukturierte Belegung wäre ein Mini-Buchungssystem (Nicht-Ziel, Adress-Design §8). Die Beschreibung gehört in die Verknüpfung, nicht in die Stammdaten des Objekts (Adress-Design §3).
- **Nächste Alternative:** Spalten Wochentag/von/bis · Wechselaufwand: 3 Spalten + Übernahme der Freitexte · Auslöser: Gino beauftragt ein Belegungs- oder Buchungsmodul
- **Umsetzung/Test:** Commit `13f640d` [SP2] (`x_objekt_gruppe.sql` v1.0.0); Spike `896b0cf` [SP1] T08/T10 ✓; Probe-DB SP4 ✓
- **Rückweg:** wie E-001
- **Review bis:** Ginos Freigabe der Adress-Konzepte (Datum offen) · Vertrauen: hoch

## E-003 — Whitespace-Normalisierung        [Klasse A · Status: entschieden (vorläufig)]
- **Gino-Bezug:** Adress-Design §7 #9; Nachricht 07.05., Punkt 9
- **Entscheidung:** als Phase 6 nach stabiler Hauptmigration.
- **Begründung:** offen
- **Nächste Alternative:** weglassen · Wechselaufwand: offen · Auslöser: offen
- **Umsetzung/Test:** offen
- **Rückweg:** offen
- **Review bis:** offen · Vertrauen: offen

## E-004 — `m_gl` → `m_mitglied`, `gl_id` → `mitglied_id`        [Klasse B · Status: getestet]
- **Gino-Bezug:** Anregung 20.04. „Kürzel ausschreiben“; Adress-Design §7 #1
- **Entscheidung:** Ovaya, 05.10.2026: jetzt umsetzen, als Welle 4 auf `feature/spaltennamen-m-gl` vor dem Rollout S9 (ein gemeinsamer Rollout mit Welle 1/2/2b). Umfang = Welle 4 nach `vorgehensplan-umbenennung-2026-09-30.md` v1.4.1 §3 (`m_gl`, `gl_id` in allen Tabellen, `gl_nr`, `x_gl_adresse`) plus `gl_adresse_id` (W4.1): **11 Vorgänge** (Mapping: `s9-arbeitsstand.md` §8 W4.1).
- **Begründung:** `[DB-NAME]` ist noch unverändert: ein Rollout, ein Rückweg-Skript, alte App-Builds brechen nur einmal (R7). Vor der Adress-Implementierung entsteht kein neuer Code mit `gl_id`, der später ein zweites Mal angepasst werden müsste.
- **Nächste Alternative:** eigener Rollout direkt nach S10 · Wechselaufwand: Welle-4-Commits auf eigenen Branch, eigener Durchlauf S7–S9 · Auslöser: Welle 4 auf der Probe-DB vor S9 nicht stabil (nicht eingetreten, W4.8 ✓)
- **Verworfen:** getrennte Migration nach Adress-Abschluss
- **Umsetzung/Test:** `s9-arbeitsstand.md` §8 (W4.0–W4.8 ✓ 05.10.); Tag `vor-welle4-2026-10-05` (= `95d6a77`, Werkzeuge [W4.2]); Commits `fbed755` [W4.6] (Prüfskripte v1.1.0), `b686b83` [W4.3] [W4.5] (17 Dateien); Branch gepusht; Probe-DB: 11 `sp_rename`, `__RefactorLog` 49, Inventar-Vergleich `GLEICH`, Rückweg getestet und erneut veröffentlicht. Kein Klasse-B-Spike, sondern Teil der Umbenennung nach Ginos Anregung 20.04. (s9 §14 Punkt 9); Rollout erst nach Gate G3 (Ginos Ja)
- **Rückweg:** Code: Tag `vor-welle4-2026-10-05`, `git revert`; DB: `tools/rename-rollback.sql` v1.1.0 (Welle 4 zuerst, dann die 38 Vorgänge; getestet W4.8 Schritt 6)
- **Review bis:** S9.6 (Nachprüfung auf `[DB-NAME]`) · Vertrauen: hoch (Probe-DB)

## E-005 — Rolle „Leser“ hat `member.create`, `fee.create`        [Klasse C · Status: vorgeschlagen]
- **Gino-Bezug:** Frage an Gino (Fehler oder gewollt?)
- **Vorschlag:** Entweder Rechte entziehen (Beschreibung sagt „Lesezugriff“) oder Beschreibung anpassen.
- **Nächste Alternative:** Beschreibung anpassen
- **Umsetzung:** nach Ginos Entscheidung im Seed **und** per Update-Skript auf `[DB-NAME]`, da der Seed nur fehlende Zeilen anlegt ([PV] Phase G)
- **Rückweg / Review:** offen

## E-006 — Rollen-Zuweisung an Benutzer fehlt in der UI        [Klasse C · Status: vorgeschlagen]
- **Gino-Bezug:** Beobachtung S8.3 (01.10.); Zuweisung heute nur per DB
- **Vorschlag:** Mehrfachauswahl im Benutzer-Dialog.
- **Nächste Alternative:** eigener Dialog „Rollen zuweisen“
- **Rückweg / Review:** offen

## E-007 — Soll-Typ-Name statt „1“ in der Gebührenliste        [Klasse A · Status: entschieden (vorläufig)]
- **Gino-Bezug:** Beobachtung S8.3 (01.10.)
- **Entscheidung:** nach dem Rollout: Name per JOIN, read-only Property.
- **Begründung:** offen
- **Nächste Alternative:** ID beibehalten · Wechselaufwand: offen · Auslöser: offen
- **Umsetzung/Test / Rückweg:** offen
- **Review bis:** offen · Vertrauen: offen

## E-008 — Indizes (Ginos Hinweis 8)        [Klasse B · Status: entschieden (vorläufig)]
- **Gino-Bezug:** Anforderungen 01.04., Hinweis 8 „Key-Index“ (kein Beleg, dass Indizes angelegt wurden)
- **Entscheidung:** Indizes auf `sta_id` (seit Welle 2 `status_id`) und `erledigt` im SSDT-Projekt anlegen.
- **Begründung:** offen. Unklar, ob Gino „Index“ oder „Key-Index-Tabelle“ meinte.
- **Nächste Alternative:** zurückstellen · Wechselaufwand: offen · Auslöser: Klärung der Bedeutung
- **Umsetzung/Test / Rückweg:** offen
- **Review bis:** Datum setzen · Vertrauen: offen

## E-009 — Namen im Objekt-Modell (Abweichung von Adress-Design v4.1)        [Klasse A · Status: getestet]
- **Gino-Bezug:** Ginos Rückmeldung 06.05. (UC-6, zusammenführen); Anregung 20.04. „Kürzel ausschreiben“
- **Entscheidung:** Junction `x_objekt_gruppe` statt `x_objekt_ygrp`; Spalte `bezeichnung` statt `name` in `m_objekt`; FK-Spalte `ygrp_id` bleibt.
- **Begründung:** `x_objekt_gruppe` folgt dem Muster `x_gruppe_mitglied` (die Tabelle `d_ygrp` heißt seit Welle 2 `d_gruppe`); `bezeichnung` wie `d_gruppe.bezeichnung` (Welle 2). `ygrp_id` wie in `m_vereinsheim.ygrp_id`, weil die `y`-Präfixe bleiben, bis ihre Bedeutung geklärt ist (s9 §18).
- **Nächste Alternative:** Namen wie in v4.1 (`x_objekt_ygrp`, `name`) bzw. `gruppe_id` · Wechselaufwand: vor dem ersten Rollout auf `[DB-NAME]` Text in 3 Projektdateien + Spike; danach Umbenennung per `.refactorlog` · Auslöser: Gino wünscht die v4.1-Namen oder eine Welle für die `y`-Präfixe
- **Umsetzung/Test:** Commits `13f640d` [SP2], `896b0cf` [SP1]; Spike 17/17 OK; Probe-DB SP4 ✓
- **Rückweg:** `git revert 13f640d`
- **Review bis:** Doku-Nachzug Adress-Design (v4.2, vor der Präsentation) · Vertrauen: hoch

## E-010 — Rollout-Reihenfolge Sportstätten        [Klasse B · Status: entschieden]
- **Gino-Bezug:** Freigabe Rollout/Merge (K-19); Datenmodell-Änderung braucht Ginos Übersicht (s9 §3 Klasse B)
- **Entscheidung:** Vorschlag Claude 05.10.: S9 vom Branch `feature/spaltennamen-m-gl` (49 Umbenennungen + Phase D), Sportstätten danach als eigener kleiner Rollout vom Branch `feature/sportstaetten-objekt` (3 neue Tabellen, 0 `sp_rename`). **Von Ovaya bestätigt am 07.10.2026 („wie vorgeschlagen“).** Für den Rollout aus dem Branch `feature/adresse-intervallschutz` (enthält Sportstätten und O-5) gilt dieselbe Reihenfolge: erst S9, dann dieser Rollout (G5).
- **Begründung:** S9 bleibt im geprüften Umfang (49, Rückweg-Skript deckt nur Umbenennungen ab). Gino sieht das neue Datenmodell, bevor es auf `[DB-NAME]` kommt.
- **Nächste Alternative:** S9 direkt vom Sportstätten-Branch (ein Rollout, eine Nachprüfung) · Wechselaufwand: anderer Branch in S9.4, Frage an Gino nennt die neuen Tabellen, Erwartung im Skript zusätzlich 3 `CREATE TABLE` · Auslöser: Ovaya will nur einen Rollout-Termin
- **Umsetzung/Test:** Probe-DB in derselben Reihenfolge (W4.8, dann SP4) ✓
- **Rückweg:** Sportstätten auf `[DB-NAME]`: `DROP TABLE` der 3 leeren Tabellen (umgekehrte FK-Reihenfolge); S9: `tools/rename-rollback.sql` v1.1.0
- **Review bis:** vor S9.4 · Vertrauen: hoch (bestätigt)

## E-011 — Name des Überlappungs-Triggers für Adressen        [Klasse A · Status: getestet]
- **Gino-Bezug:** Ginos Review 06.05.2026 (Überlappung der Gültigkeitszeiträume im DDL schützen); Adress-Design v4.1 §9 V1 nennt den Trigger `tr_x_gl_adresse_no_overlap`
- **Entscheidung:** Ovaya, 07.10.2026: Der Trigger heißt `tr_x_mitglied_adresse_no_overlap` (Tabelle seit Welle 4: `x_mitglied_adresse`). Dateiname `x_gl_adresse.sql` sowie `ck_x_gl_adresse_zeitraum`, `uq_x_gl_adresse_aktiv` und `ix_x_gl_adresse_zeitraum` bleiben (Welle 3 zurückgestellt).
- **Begründung:** Neue Objekte folgen dem aktuellen Tabellennamen (E-004), sonst trägt ein frisch angelegtes Objekt den Namen aus der Zeit vor Welle 4. Die bestehenden Constraint-Namen werden gebündelt in Welle 3 geändert.
- **Nächste Alternative:** `tr_x_gl_adresse_no_overlap` (Name in v4.1 und bei Gino) · Wechselaufwand: Trigger-Datei, `.sqlproj`-Zeile und Testskript prüfen, erneut veröffentlichen · Auslöser: Gino lehnt den Namen ab. Der Grund „v4.1 nennt einen anderen Namen“ entfällt mit dem Doku-Nachzug v4.2.
- **Umsetzung/Test:** Branch `feature/adresse-intervallschutz`, Commits `6ffbc1e` [O5.7] (Trigger, `.sqlproj`, Test v1.0.0) und `07ba7a2` [O5.13] (CHECK `>`, Test v1.1.0); Probe-DB: `tools/test-adresse-no-overlap.sql` v1.1.0, 10/10 OK. Für O-5 gibt es keine E-ID in den Commit-Nachrichten (s9 §14 Punkt 48); der Eintrag ist nachträglich.
- **Rückweg:** Code: `git revert 6ffbc1e`; DB: `DROP TRIGGER [yam3].[tr_x_mitglied_adresse_no_overlap]` (nur Probe-DB)
- **Review bis:** vor G5 / Rollout O-3 (Trigger auf `[DB-NAME]`) · Vertrauen: hoch (Test 10/10)
