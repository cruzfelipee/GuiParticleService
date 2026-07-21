local RunService = game:GetService("RunService")

local ProjectileType = require(script.Parent.ProjectileType)

local Projectiles: { ProjectileType.Projectile } = {}

local ProjectileService = {}

function ProjectileService.registerProjectile(projectile: ProjectileType.Projectile)
	table.insert(Projectiles, projectile)
end

function ProjectileService.removeProjectile(projectile: ProjectileType.Projectile)
	local index = table.find(Projectiles, projectile)
	if index then
		table.remove(Projectiles, index)
	end
end

function ProjectileService.getProjectiles(): { ProjectileType.Projectile }
	return Projectiles
end

function ProjectileService.updateProjectiles(deltaTime: number)
	for _, v in Projectiles do
		v:Step(deltaTime)
	end
end

RunService.Heartbeat:Connect(ProjectileService.updateProjectiles)

return ProjectileService
