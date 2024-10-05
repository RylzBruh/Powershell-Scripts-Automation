# Connect to Azure account
Connect-AzAccount

# Function to select a user interactively
function Select-AzUser {
    $users = Get-AzADUser | Out-GridView -Title "Select a user" -PassThru
    return $users.Id
}

# Function to select a group interactively
function Select-AzGroup {
    $groups = Get-AzADGroup | Out-GridView -Title "Select a group" -PassThru
    return $groups.Id
}

# Function to select multiple roles interactively
function Select-AzRoles {
    $roles = Get-AzRoleDefinition | Where-Object { $_.RoleName -like "*Storage*" -or $_.Description -like "*Storage*" } | Out-GridView -Title "Select one or more roles to assign" -PassThru
    return $roles
}

# Ask the user to select whether they want to assign a role to a user or a group
$userOrGroupChoice = Read-Host -Prompt "Do you want to assign the role to a 'User' or a 'Group'? Enter 'User' or 'Group'"

# Get the Object ID based on the user's selection
if ($userOrGroupChoice -eq "User") {
    $userOrGroupId = Select-AzUser
} elseif ($userOrGroupChoice -eq "Group") {
    $userOrGroupId = Select-AzGroup
} else {
    Write-Host "Invalid choice. Please run the script again and select either 'User' or 'Group'."
    exit
}

# Select multiple roles to assign
$selectedRoles = Select-AzRoles

# Ensure that at least one role is selected
if (!$selectedRoles) {
    Write-Host "No roles selected. Exiting."
    exit
}

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Let the user choose one or more subscriptions
$selectedSubscriptions = $subscriptions | Out-GridView -Title "Select one or more subscriptions" -PassThru

# Loop through the selected subscriptions
$selectedSubscriptions | ForEach-Object {
    $subscription = $_
    Write-Host "Switching to subscription: $($subscription.Name)"
    Set-AzContext -Subscription $subscription.Id

    # Get all storage accounts in the selected subscription
    $storageAccounts = Get-AzStorageAccount
    
    # Let the user choose one or more storage accounts
    $selectedStorageAccounts = $storageAccounts | Out-GridView -Title "Select one or more storage accounts in $($subscription.Name)" -PassThru

    # Loop through the selected storage accounts
    $selectedStorageAccounts | ForEach-Object {
        $storageAccount = $_
        $storageAccountName = $storageAccount.StorageAccountName
        $resourceGroupName = $storageAccount.ResourceGroupName
        $resourceId = "/subscriptions/$($subscription.Id)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($storageAccountName)"

        # Loop through the selected roles and assign them one by one
        $selectedRoles | ForEach-Object {
            $role = $_
            try {
                Write-Host "Assigning role '$($role.Name)' for storage account: $storageAccountName"
                New-AzRoleAssignment -ObjectId $userOrGroupId -RoleDefinitionName $role.Name -Scope $resourceId
                Write-Host "Role '$($role.Name)' assigned successfully for storage account: $storageAccountName"
            }
            catch {
                Write-Host "Failed to assign role '$($role.Name)' for storage account: $storageAccountName. Error: $_"
            }
        }
    }
    
    Write-Host "Finished processing selected storage accounts for subscription: $($subscription.Name)"
}
