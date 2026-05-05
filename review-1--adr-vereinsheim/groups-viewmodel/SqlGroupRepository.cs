// Ziel: yam2/Services/SqlGroupRepository.cs
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Threading.Tasks;
using yam2.Core;
using yam2.Models;

namespace yam2.Services
{
    public class SqlGroupRepository : SqlRepositoryBase, IGroupRepository
    {
        public SqlGroupRepository(string connectionString) : base(connectionString) { }

        public Task<IEnumerable<Group>> GetAllAsync()
        {
            return WithConnectionAsync(async conn =>
            {
                var result = new List<Group>();
                using (var cmd = new SqlCommand(
                    "SELECT [id], [bez] FROM [yam3].[d_ygrp] ORDER BY [bez]", conn))
                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                        result.Add(new Group { Id = reader.GetInt32(0), Bezeichnung = reader.GetString(1) });
                }
                return (IEnumerable<Group>)result;
            });
        }

        public Task<int> AddAsync(Group group)
        {
            return WithConnectionAsync(async conn =>
            {
                using (var cmd = new SqlCommand(
                    "INSERT INTO [yam3].[d_ygrp] ([bez]) OUTPUT INSERTED.[id] VALUES (@bez)", conn))
                {
                    cmd.Parameters.AddWithValue("@bez", group.Bezeichnung);
                    return (int)await cmd.ExecuteScalarAsync();
                }
            });
        }

        public Task UpdateAsync(Group group)
        {
            return WithConnectionAsync<int>(async conn =>
            {
                using (var cmd = new SqlCommand(
                    "UPDATE [yam3].[d_ygrp] SET [bez] = @bez WHERE [id] = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@bez", group.Bezeichnung);
                    cmd.Parameters.AddWithValue("@id",  group.Id);
                    return await cmd.ExecuteNonQueryAsync();
                }
            });
        }

        public Task DeleteAsync(int id)
        {
            return WithConnectionAsync<int>(async conn =>
            {
                using (var cmd = new SqlCommand(
                    "DELETE FROM [yam3].[d_ygrp] WHERE [id] = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    return await cmd.ExecuteNonQueryAsync();
                }
            });
        }

        public Task<IEnumerable<GroupMember>> GetMembersAsync(int groupId)
        {
            return WithConnectionAsync(async conn =>
            {
                var result = new List<GroupMember>();
                using (var cmd = new SqlCommand(
                    @"SELECT g.[gl_id], m.[vn] + ' ' + m.[nn], g.[seit]
                      FROM   [yam3].[x_gm]  g
                      INNER JOIN [yam3].[m_gl] m ON m.[id] = g.[gl_id]
                      WHERE  g.[ygrp_id] = @ygrp_id
                      ORDER  BY m.[nn], m.[vn]", conn))
                {
                    cmd.Parameters.AddWithValue("@ygrp_id", groupId);
                    using (var reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            result.Add(new GroupMember
                            {
                                GlId      = reader.GetInt32(0),
                                VollerName = reader.GetString(1),
                                Seit      = reader.GetDateTime(2)
                            });
                        }
                    }
                }
                return (IEnumerable<GroupMember>)result;
            });
        }

        public Task<IEnumerable<LookupItem>> GetAvailableMembersAsync(int groupId)
        {
            return WithConnectionAsync(async conn =>
            {
                var result = new List<LookupItem>();
                using (var cmd = new SqlCommand(
                    @"SELECT [id], [vn] + ' ' + [nn]
                      FROM   [yam3].[m_gl]
                      WHERE  [sta_id] <> 6
                        AND  [id] NOT IN (
                                 SELECT [gl_id] FROM [yam3].[x_gm] WHERE [ygrp_id] = @ygrp_id)
                      ORDER  BY [nn], [vn]", conn))
                {
                    cmd.Parameters.AddWithValue("@ygrp_id", groupId);
                    using (var reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                            result.Add(new LookupItem(reader.GetInt32(0), reader.GetString(1)));
                    }
                }
                return (IEnumerable<LookupItem>)result;
            });
        }

        public Task AddMemberAsync(int groupId, int memberId, DateTime seit)
        {
            return WithConnectionAsync<int>(async conn =>
            {
                using (var cmd = new SqlCommand(
                    "INSERT INTO [yam3].[x_gm] ([gl_id], [ygrp_id], [seit]) VALUES (@gl_id, @ygrp_id, @seit)", conn))
                {
                    cmd.Parameters.AddWithValue("@gl_id",   memberId);
                    cmd.Parameters.AddWithValue("@ygrp_id", groupId);
                    cmd.Parameters.AddWithValue("@seit",    seit.Date);
                    return await cmd.ExecuteNonQueryAsync();
                }
            });
        }

        public Task RemoveMemberAsync(int groupId, int memberId)
        {
            return WithConnectionAsync<int>(async conn =>
            {
                using (var cmd = new SqlCommand(
                    "DELETE FROM [yam3].[x_gm] WHERE [ygrp_id] = @ygrp_id AND [gl_id] = @gl_id", conn))
                {
                    cmd.Parameters.AddWithValue("@ygrp_id", groupId);
                    cmd.Parameters.AddWithValue("@gl_id",   memberId);
                    return await cmd.ExecuteNonQueryAsync();
                }
            });
        }
    }
}
