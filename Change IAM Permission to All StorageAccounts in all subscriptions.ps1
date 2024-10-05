# Connect to Azure account
Connect-AzAccount

# Define the user/group to which the IAM roles will be assigned
$userOrGroup = "User\groupID"

# Loop through all subscriptions
Get-AzSubscription | ForEach-Object {
    $subscription = $_
    Set-AzContext -Subscription $subscription.Id
    
    # Loop through all storage accounts in the subscription
    Get-AzStorageAccount | ForEach-Object {
        $storageAccount = $_
        $storageAccountName = $storageAccount.StorageAccountName
        $resourceGroupName = $storageAccount.ResourceGroupName
        $resourceId = "/subscriptions/$($subscription.Id)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($storageAccountName)"

        # Add IAM role (example: Storage Blob Data Contributor) to the user/group for each storage account
        New-AzRoleAssignment -ObjectId $userOrGroup -RoleDefinitionId "ba92f5b4-2d11-453d-a403-e96b0029c9fe" -Scope $resourceId
        
        # Add other roles as needed below by uncommenting or adding
        # New-AzRoleAssignment -ObjectId $userOrGroup -RoleDefinitionName "Storage Account Contributor" -Scope $resourceId
    }
}

# Comment: IAM Roles and their description in Azure
# Storage Blob Data Contributor - Provides access to blob containers and data, but not to the storage account settings.
# Storage Account Contributor - Grants full access to manage storage accounts, except access to keys.
# Storage Queue Data Contributor - Provides access to queue messages, but not account settings.
# Storage File Data SMB Share Contributor - Provides full access to Azure Files SMB shares.
# Contributor - Grants full access to manage all Azure resources, but not assign roles.
# Owner - Grants full access to all resources and permissions, including assigning roles.
