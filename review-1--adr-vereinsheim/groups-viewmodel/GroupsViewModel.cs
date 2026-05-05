// Ziel: yam2/ViewModels/GroupsViewModel.cs
//
// DI-Registrierung in App.xaml.cs (Composition Root):
//   services.AddSingleton<IGroupRepository>(p => new SqlGroupRepository(connStr));
//   services.AddTransient<GroupDetailViewModel>();
//   services.AddTransient<GroupMemberAddViewModel>();
//   services.AddTransient<GroupsViewModel>(p => new GroupsViewModel(
//       p.GetRequiredService<IGroupRepository>(),
//       p.GetRequiredService<IViewService>(),
//       group => new GroupDetailViewModel(group),
//       (members, name) => new GroupMemberAddViewModel(members, name)));
//
// IViewService — zwei neue Methoden ergänzen:
//   bool? ShowGroupDetail(GroupDetailViewModel vm);
//   bool? ShowGroupMemberAdd(GroupMemberAddViewModel vm);
//
// MainWindow.xaml — DataTemplate ergänzen:
//   <DataTemplate DataType="{x:Type vm:GroupsViewModel}">
//       <v:GroupsView />
//   </DataTemplate>
//
// MainViewModel — NavigateToGroupsCommand + GroupsViewModel Property ergänzen.

using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using yam2.Core;
using yam2.Models;
using yam2.Services;

namespace yam2.ViewModels
{
    public class GroupsViewModel : ViewModelBase
    {
        private readonly IGroupRepository                          _groupRepo;
        private readonly IViewService                             _viewService;
        private readonly Func<Group, GroupDetailViewModel>        _detailFactory;
        private readonly Func<IEnumerable<LookupItem>, string, GroupMemberAddViewModel> _memberAddFactory;

        private Group       _selectedGroup;
        private GroupMember _selectedMember;

        public ObservableCollection<Group>       Groups  { get; } = new ObservableCollection<Group>();
        public ObservableCollection<GroupMember> Members { get; } = new ObservableCollection<GroupMember>();

        public Group SelectedGroup
        {
            get { return _selectedGroup; }
            set
            {
                if (SetProperty(ref _selectedGroup, value))
                {
                    EditGroupCommand.RaiseCanExecuteChanged();
                    DeleteGroupCommand.RaiseCanExecuteChanged();
                    AddMemberCommand.RaiseCanExecuteChanged();
                    _reloadMembersCommand.Execute(null);
                }
            }
        }

        public GroupMember SelectedMember
        {
            get { return _selectedMember; }
            set
            {
                SetProperty(ref _selectedMember, value);
                DeleteMemberCommand.RaiseCanExecuteChanged();
            }
        }

        public AsyncRelayCommand LoadCommand         { get; }
        public AsyncRelayCommand AddGroupCommand     { get; }
        public AsyncRelayCommand EditGroupCommand    { get; }
        public AsyncRelayCommand DeleteGroupCommand  { get; }
        public AsyncRelayCommand AddMemberCommand    { get; }
        public AsyncRelayCommand DeleteMemberCommand { get; }

        private readonly AsyncRelayCommand _reloadMembersCommand;

        public GroupsViewModel(
            IGroupRepository                          groupRepo,
            IViewService                              viewService,
            Func<Group, GroupDetailViewModel>         detailFactory,
            Func<IEnumerable<LookupItem>, string, GroupMemberAddViewModel> memberAddFactory)
        {
            _groupRepo        = groupRepo;
            _viewService      = viewService;
            _detailFactory    = detailFactory;
            _memberAddFactory = memberAddFactory;

            LoadCommand           = new AsyncRelayCommand(LoadGroupsAsync,  onError: HandleError);
            AddGroupCommand       = new AsyncRelayCommand(AddGroupAsync,    onError: HandleError);
            EditGroupCommand      = new AsyncRelayCommand(EditGroupAsync,   () => _selectedGroup  != null, onError: HandleError);
            DeleteGroupCommand    = new AsyncRelayCommand(DeleteGroupAsync, () => _selectedGroup  != null, onError: HandleError);
            AddMemberCommand      = new AsyncRelayCommand(AddMemberAsync,   () => _selectedGroup  != null, onError: HandleError);
            DeleteMemberCommand   = new AsyncRelayCommand(DeleteMemberAsync, () => _selectedMember != null, onError: HandleError);
            _reloadMembersCommand = new AsyncRelayCommand(LoadMembersAsync,  onError: HandleError);
        }

        private async Task LoadGroupsAsync()
        {
            IsLoading = true;
            try
            {
                var groups = await _groupRepo.GetAllAsync();
                Groups.Clear();
                foreach (var g in groups)
                    Groups.Add(g);
            }
            finally { IsLoading = false; }
        }

        private async Task LoadMembersAsync()
        {
            Members.Clear();
            SelectedMember = null;
            if (_selectedGroup == null) return;

            var members = await _groupRepo.GetMembersAsync(_selectedGroup.Id);
            foreach (var m in members)
                Members.Add(m);
        }

        private async Task AddGroupAsync()
        {
            var vm = _detailFactory(null);
            if (_viewService.ShowGroupDetail(vm) != true) return;

            var id = await _groupRepo.AddAsync(vm.Group);
            vm.Group.Id = id;
            Groups.Add(vm.Group);
            SelectedGroup = vm.Group;
            SetStatus("Gruppe gespeichert.");
        }

        private async Task EditGroupAsync()
        {
            var original = _selectedGroup;
            var copy     = original.Clone();
            var vm       = _detailFactory(copy);
            if (_viewService.ShowGroupDetail(vm) != true) return;

            await _groupRepo.UpdateAsync(copy);
            original.CopyFrom(copy);
            SetStatus("Gruppe aktualisiert.");
        }

        private async Task DeleteGroupAsync()
        {
            var target = _selectedGroup;
            await _groupRepo.DeleteAsync(target.Id);
            Groups.Remove(target);
            SelectedGroup = null;
            SetStatus("Gruppe gelöscht.");
        }

        private async Task AddMemberAsync()
        {
            var available = await _groupRepo.GetAvailableMembersAsync(_selectedGroup.Id);
            var vm        = _memberAddFactory(available, _selectedGroup.Bezeichnung);
            if (_viewService.ShowGroupMemberAdd(vm) != true) return;

            await _groupRepo.AddMemberAsync(_selectedGroup.Id, vm.SelectedMemberId, vm.Seit);
            await LoadMembersAsync();
            SetStatus("Mitglied zugeordnet.");
        }

        private async Task DeleteMemberAsync()
        {
            var member = _selectedMember;
            await _groupRepo.RemoveMemberAsync(_selectedGroup.Id, member.GlId);
            Members.Remove(member);
            SelectedMember = null;
            SetStatus("Mitglied aus Gruppe entfernt.");
        }

        private void HandleError(Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }
}
