# Arbeitslog — 05.05.2026

**Projekt:** yam2 | **Bearbeiter:** Azubi | **Ausbilder:** Gino

---

## Erledigt

| # | Aufgabe |
|---|---|
| 1 | Adress-DDL (6 Tabellen + Trigger) als SSDT-fertige .sql-Dateien erstellt → `review-1--adr-vereinsheim/ssdt/` |
| 2 | `d_ygrp.sql` mit `vereinssitz_adresse_id` ergänzt (vollständige Neufassung für SSDT) |
| 3 | `adress-design.md` aktualisiert: Section 6.1/6.3/6.4 auf Stand 05.05., Section 7 mit Freigabe-Spalte |
| 4 | `GroupsViewModel` vollständig implementiert: `Group.cs`, `GroupMember.cs`, `IGroupRepository.cs`, `SqlGroupRepository.cs`, `GroupsViewModel.cs`, `GroupDetailViewModel.cs`, `GroupMemberAddViewModel.cs` → `review-1--adr-vereinsheim/groups-viewmodel/` |

---

## Hinweise

**⚠️ Trigger-Bugfix in `tr_m_adresse_immutable`**
- Originaler Entwurf: `IF CONTEXT_INFO() <> CAST('adresse_korrektur' AS VARBINARY(128))`
- Problem: `CONTEXT_INFO()` = `NULL` im Initialzustand → `NULL <> x` = `NULL` → kein Fehler → Trigger bypassed
- Fix in `ssdt/yam3/Triggers/tr_m_adresse_immutable.sql`: `DECLARE @ctx ... IF @ctx IS NULL OR @ctx <> ...`
- DDL-Block in `adress-design.md` Section 4.4 enthält noch den alten Stand (dokumentarisch, SSDT-Datei ist maßgeblich)

**ℹ️ SSDT-Dateien ins Projekt einbinden**

Schritte im lokalen SSDT-Projekt:

1. Dateien aus `ssdt/yam3/Tables/` in `yam2.Database/yam3/Tables/` kopieren (d_land, d_ort, m_adresse, x_gl_adresse, m_sportstaette, m_vereinsheim)
2. `ssdt/yam3/Tables/d_ygrp.sql` → bestehende `yam2.Database/yam3/Tables/d_ygrp.sql` ersetzen
3. `ssdt/yam3/Triggers/tr_m_adresse_immutable.sql` → `yam2.Database/yam3/Triggers/` (Ordner neu anlegen falls nicht vorhanden)
4. `ssdt/Scripts/PostDeployment/d_land_seed.sql` → `yam2.Database/Scripts/PostDeployment/` (Ordner ggf. neu)
5. Alle neuen Dateien im `.sqlproj` einbinden (Rechtsklick → Add Existing Item oder Project-Datei manuell editieren)
6. Build ausführen → Fehler beheben

**ℹ️ GroupsViewModel ins yam2-Projekt übernehmen**

| Datei | Ziel im Projekt |
|---|---|
| `Group.cs` | `yam2/Models/Group.cs` |
| `GroupMember.cs` | `yam2/Models/GroupMember.cs` |
| `IGroupRepository.cs` | `yam2/Services/IGroupRepository.cs` |
| `SqlGroupRepository.cs` | `yam2/Services/SqlGroupRepository.cs` |
| `GroupsViewModel.cs` | `yam2/ViewModels/GroupsViewModel.cs` |
| `GroupDetailViewModel.cs` | `yam2/ViewModels/GroupDetailViewModel.cs` |
| `GroupMemberAddViewModel.cs` | `yam2/ViewModels/GroupMemberAddViewModel.cs` |

**Noch in yam2 ergänzen (nicht in diesem Repo):**

- `IViewService` — zwei neue Methoden:
  ```csharp
  bool? ShowGroupDetail(GroupDetailViewModel vm);
  bool? ShowGroupMemberAdd(GroupMemberAddViewModel vm);
  ```
- `ViewService` — Implementierung der neuen Methoden (analog bestehende Detail-Dialoge)
- `GroupsView.xaml` — DataGrid Groups + DataGrid Members + Toolbar-Buttons
- `MainWindow.xaml` — DataTemplate `GroupsViewModel → GroupsView` ergänzen
- `MainViewModel` — `NavigateToGroupsCommand` + `GroupsViewModel`-Property
- `App.xaml.cs` (Composition Root) — DI-Registrierung laut Kommentar in `GroupsViewModel.cs`
- `MappingProfile` — `CreateMap<Group, Group>().ForMember(dest => dest.Id, opt => opt.Ignore())`

---

## Noch offen

| # | Aufgabe | Bemerkung |
|---|---|---|
| 1 | SSDT Build → Fehler beheben | Lokal in VS ausführen |
| 2 | Git-Commit DB-Projekt | Nach erfolgreichem Build |
| 3 | Gino-Freigabe `adress-design.md` | 6 offene Entscheidungen (Section 7) |
| 4 | GroupsViewModel in yam2 einbauen | Abhängig von IViewService-Erweiterung |
| 5 | `GroupsView.xaml` erstellen | Nach Gino-Freigabe |
