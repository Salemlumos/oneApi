using Microsoft.EntityFrameworkCore;
using Endpoints.Models;

namespace Api.Database
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Role> Roles { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
                    modelBuilder.Entity<Role>().HasData(
                        new Role { Id = 1, Name = "Admin" },
                        new Role { Id = 2, Name = "User" }
                    );
        }
    }
}
