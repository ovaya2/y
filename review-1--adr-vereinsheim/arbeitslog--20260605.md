# Arbeitslog — 06.05.2026

**Projekt:** yam2 | **Bearbeiter:** Azubi | **Ausbilder:** Gino

---

## Erledigt

| # | Aufgabe |
|---|---|
| 1 | **Gruppen & Funktionen** — vollständig implementiert: `Group.cs`, `GroupMember.cs`, `FunctionMember.cs`, `IGroupRepository.cs`, `SqlGroupRepository.cs`, `GroupsViewModel.cs`, `GroupDetailViewModel.cs`, `GroupMemberAddViewModel.cs`, `GroupsView.xaml`, `GroupDetailView.xaml`, `GroupMemberAddView.xaml`, `IViewService`-Erweiterung, `ViewService`-Implementierung, Navigation in `MainViewModel` (Factory-Delegate), DI-Registrierung in `App.xaml.cs`, `MappingProfile`-Eintrag |
| 2 | **SSDT-Projekt** (`yam2.Database`) eingerichtet: Live-Schema aus `[DB-SERVER].[DB-NAME]` importiert, Tabellen/Trigger/SPs als `.sql`-Dateien strukturiert |
| 3 | **Adress-DDL** (SSDT-fertig): 6 Tabellen (`d_land`, `d_ort`, `m_adresse`, `x_gl_adresse`, `m_sportstaette`, `m_vereinsheim`) + Trigger `tr_m_adresse_immutable` (inkl. NULL-Fix für `CONTEXT_INFO()`), `d_ygrp` mit `vereinssitz_adresse_id` erweitert |
| 4 | **`adress-design.md` v4**: Gino-Feedback eingearbeitet — UC-6 Sportstätte ergänzt, `m_objekt`/`d_objekttyp`-Merge, Overlap-Trigger, Whitespace-Computed-Columns |

---

