using Endpoints.Models;
using Endpoints.Interfaces;
using Endpoints.Repositories;

namespace Endpoints.Services
{
    public class RoleService
    {
        private readonly IRoleRepository _roleRepository;

        public RoleService(IRoleRepository roleRepository)
        {
            _roleRepository = roleRepository;
        }

        public Task<List<Role>> GetRolesAsync() => _roleRepository.GetRolesAsync();
        public Task<Role?> GetRoleByIdAsync(int id) => _roleRepository.GetRoleByIdAsync(id);
        public Task<Role> CreateRoleAsync(Role role) => _roleRepository.CreateRoleAsync(role);
        public Task<Role?> UpdateRoleAsync(int id, Role role) => _roleRepository.UpdateRoleAsync(id, role);
        public Task<bool> DeleteRoleAsync(int id) => _roleRepository.DeleteRoleAsync(id);
    }
}
