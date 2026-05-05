// Ziel: yam2/ViewModels/GroupMemberAddViewModel.cs
using System;
using System.Collections.Generic;
using yam2.Core;
using yam2.Models;

namespace yam2.ViewModels
{
    public class GroupMemberAddViewModel : ObservableObject
    {
        private LookupItem _selectedMember;
        private DateTime   _seit = DateTime.Today;

        public string                 GroupName        { get; }
        public IEnumerable<LookupItem> AvailableMembers { get; }
        public Action<bool>           CloseAction      { get; set; }

        public LookupItem SelectedMember
        {
            get { return _selectedMember; }
            set
            {
                SetProperty(ref _selectedMember, value);
                SaveCommand.RaiseCanExecuteChanged();
            }
        }

        public DateTime Seit
        {
            get { return _seit; }
            set { SetProperty(ref _seit, value); }
        }

        public int SelectedMemberId => _selectedMember?.Id ?? 0;

        public RelayCommand SaveCommand   { get; }
        public RelayCommand CancelCommand { get; }

        public GroupMemberAddViewModel(IEnumerable<LookupItem> availableMembers, string groupName)
        {
            AvailableMembers = availableMembers;
            GroupName        = groupName;
            SaveCommand      = new RelayCommand(Save, () => _selectedMember != null);
            CancelCommand    = new RelayCommand(() => CloseAction?.Invoke(false));
        }

        private void Save()
        {
            CloseAction?.Invoke(true);
        }
    }
}
