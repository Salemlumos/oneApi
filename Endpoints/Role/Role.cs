using System.ComponentModel.DataAnnotations;

namespace Endpoints.Models
{
    public class Role
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; } = String.Empty;
    }
}