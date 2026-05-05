// Ziel: yam2/Services/IGroupRepository.cs
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using yam2.Models;

namespace yam2.Services
{
    public interface IGroupRepository
    {
        Task<IEnumerable<Group>>      GetAllAsync();
        Task<int>                     AddAsync(Group group);
        Task                          UpdateAsync(Group group);
        Task                          DeleteAsync(int id);
        Task<IEnumerable<GroupMember>> GetMembersAsync(int groupId);
        Task<IEnumerable<LookupItem>> GetAvailableMembersAsync(int groupId);
        Task                          AddMemberAsync(int groupId, int memberId, DateTime seit);
        Task                          RemoveMemberAsync(int groupId, int memberId);
    }
}
