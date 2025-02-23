using Endpoints.Models;
using Endpoints.Dtos;
using Endpoints.Services;
using Microsoft.AspNetCore.Mvc;

namespace Endpoints.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MainRoleController : ControllerBase
    {
        private readonly RoleService _roleService;

        public RoleController(RoleService roleService)
        {
            _roleService = roleService;
        }

        // GET: api/role
        [HttpGet]
        public async Task<ActionResult<List<GetRoleDto>>> GetRoles()
        {
            var roles = await _roleService.GetRolesAsync();
            var rolesDto = roles.Select(role => new GetRoleDto
            {
                Id = role.Id,
                Name = role.Name
            }).ToList();

            return Ok(rolesDto);
        }

        // GET: api/role/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<GetRoleDto>> GetRole(int id)
        {
            var role = await _roleService.GetRoleByIdAsync(id);
            if (role == null)
            {
                return NotFound();
            }

            var roleDto = new RoleDto
            {
                Id = role.Id,
                Name = role.Name
            };

            return Ok(roleDto);
        }

        // POST: api/role
        [HttpPost]
        public async Task<ActionResult<RoleDto>> CreateRole(CreateRoleDto roleDto)
        {
            var role = new Role
            {
                Name = roleDto.Name
            };

            var createdRole = await _roleService.CreateRoleAsync(role);

            return CreatedAtAction(nameof(GetRole), new { id = createdRole.Id }, createdRole);
        }

        // PUT: api/role/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<RoleDto>> UpdateRole(int id, RoleDto roleDto)
        {
            var role = new Role
            {
                Id = id,
                Name = roleDto.Name
            };

            var updatedRole = await _roleService.UpdateRoleAsync(id, role);

            if (updatedRole == null)
            {
                return NotFound();
            }

            return Ok(updatedRole);
        }

        // DELETE: api/role/{id}
        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteRole(int id)
        {
            var success = await _roleService.DeleteRoleAsync(id);

            if (!success)
            {
                return NotFound();
            }

            return NoContent();
        }
    }
}
