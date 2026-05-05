// Ziel: yam2/ViewModels/GroupDetailViewModel.cs
using System;
using yam2.Core;
using yam2.Models;

namespace yam2.ViewModels
{
    public class GroupDetailViewModel : ObservableObject
    {
        public Group          Group         { get; }
        public string         Title         { get; }
        public Action<bool>   CloseAction   { get; set; }
        public RelayCommand   SaveCommand   { get; }
        public RelayCommand   CancelCommand { get; }

        // group == null → neuer Eintrag; group != null → Bearbeiten (Clone übergeben)
        public GroupDetailViewModel(Group group)
        {
            Group  = group ?? new Group();
            Title  = group == null ? "Gruppe hinzufügen" : "Gruppe bearbeiten";

            SaveCommand   = new RelayCommand(Save);
            CancelCommand = new RelayCommand(() => CloseAction?.Invoke(false));
        }

        private void Save()
        {
            Group.Bezeichnung = Group.Bezeichnung?.Trim() ?? string.Empty;
            if (Group.HasErrors) return;
            CloseAction?.Invoke(true);
        }
    }
}
