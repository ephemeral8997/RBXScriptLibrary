local function hookRemote(remote)
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            print("RemoteEvent fired:", remote.Name)
            local args = {...}
            for i, v in ipairs(args) do
                print("Arg", i, ":", v)
            end
        end)
    end
end

local replicatedStorage = game:GetService("ReplicatedStorage")

for _, obj in ipairs(replicatedStorage:GetDescendants()) do
    hookRemote(obj)
end

replicatedStorage.DescendantAdded:Connect(function(obj)
    hookRemote(obj)
end)
