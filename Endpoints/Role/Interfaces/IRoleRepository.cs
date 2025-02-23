using Endpoints.Models;

namespace Endpoints.Interfaces
{
    public interface IRoleRepository
    {
        Task<List<Role>> GetRolesAsync();
        Task<Role?> GetRoleByIdAsync(int id);
        Task<Role> CreateRoleAsync(Role role);
        Task<Role?> UpdateRoleAsync(int id, Role role);
        Task<bool> DeleteRoleAsync(int id);
    }
}
