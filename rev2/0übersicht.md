# v3 → Gino-Feedback → v4

## A. Auf einen Blick

| Feedback-Punkt vom 06.05.2026 | Schwere | In v4 umgesetzt? | Wo? |
|---|---|---|---|
| 1. PLZ als VARCHAR + Intervall-Modell — Lob | 🟢 | ✓ unverändert übernommen | §3, §4.4 |
| 2. UC-6 Sportstätte verknüpfungstechnisch leer | 🔴 | ✓ vollständig | §3 (neuer Logik-Eintrag), §4.1, §4.4 (`x_objekt_ygrp`) |
| 3. Vereinsheim + Sportstätte zusammenführen | 🟡 | ✓ vollständig | §3 (geänderter Logik-Eintrag), §4.1, §4.4 (`m_objekt` + `d_objekttyp`) |
| 4. Intervall-Überlappungsschutz im DDL | 🔴 | ✓ als Trigger (siehe Hinweis unten) | §3 (neuer Logik-Eintrag), §4.3, §4.4 (`tr_x_gl_adresse_no_overlap`) |
| 5. Whitespace-Normalisierung — nice-to-have | 🟢 | ✓ als optionale Phase 6 | §5 (Phase 6), §6.1, §7 #9 |
| Offene Frage: d_objekttyp-Inhalte | — | ✓ aufgenommen | §7 #6 |
| Offene Frage: Vereinssitz-Variante | — | ✓ aufgenommen + Default-Vorschlag | §7 #7 |
| Offene Frage: Beschreibung Freitext vs. strukturiert | — | ✓ aufgenommen | §7 #8 |
| Offene Frage: Whitespace als Phase 6 | — | ✓ aufgenommen | §7 #9 |

**Hinweis zu Punkt 4:** „im DDL schützen" — v4 nutzt einen AFTER-Trigger statt eines deklarativen Constraints. Begründung: SQL Server kennt vor System-Versioned-Tables keinen temporalen Operator für „überlappende Intervalle"; ein normaler `CHECK`/`UNIQUE` kann das nicht ausdrücken. Trigger ist die etablierte Lösung.
