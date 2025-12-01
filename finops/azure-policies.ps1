param(
  string $resourceGroupName = "icesi-dev-rg"
)

# FinOps Policy Enforcement using Azure Policy
# Asegura que los recursos cumplan con políticas de costo

Write-Host "Applying FinOps policies to resource group: $resourceGroupName" -ForegroundColor Cyan

# Policy 1: Enforce tags on all resources
$tagPolicy = @{
  "displayName" = "Require 'environment' tag for cost tracking"
  "description" = "Requires environment tag (dev/staging/prod) on all resources"
  "mode" = "All"
  "policyRule" = @{
    "if" = @{
      "field" = "[tags['environment']]"
      "exists" = "false"
    }
    "then" = @{
      "effect" = "deny"
    }
  }
}

# Policy 2: Prevent expensive SKUs
$skuPolicy = @{
  "displayName" = "Restrict expensive VM SKUs"
  "description" = "Prevent provisioning of expensive VM sizes"
  "mode" = "All"
  "policyRule" = @{
    "if" = @{
      "allOf" = @(
        @{
          "field" = "type"
          "equals" = "Microsoft.Compute/virtualMachines"
        },
        @{
          "field" = "Microsoft.Compute/virtualMachines/hardwareProfile.vmSize"
          "in" = @(
            "Standard_E16s_v3",
            "Standard_E20s_v3",
            "Standard_E32s_v3",
            "Standard_G5",
            "Standard_M128s"
          )
        }
      )
    }
    "then" = @{
      "effect" = "deny"
    }
  }
}

# Policy 3: Audit resources without Spot priority (for optimization)
$spotAuditPolicy = @{
  "displayName" = "Audit VMSS without Spot priority"
  "description" = "Identifies VMSS that should use Spot instances for cost savings"
  "mode" = "All"
  "policyRule" = @{
    "if" = @{
      "allOf" = @(
        @{
          "field" = "type"
          "equals" = "Microsoft.Compute/virtualMachineScaleSets"
        },
        @{
          "field" = "Microsoft.Compute/virtualMachineScaleSets/virtualMachineProfile.priority"
          "notEquals" = "Spot"
        }
      )
    }
    "then" = @{
      "effect" = "audit"
    }
  }
}

# Policy 4: Enforce storage access tier (hot vs cool)
$storagePolicy = @{
  "displayName" = "Enforce cool storage tier for blobs over 30 days"
  "description" = "Requires lifecycle policies for storage cost optimization"
  "mode" = "All"
  "policyRule" = @{
    "if" = @{
      "allOf" = @(
        @{
          "field" = "type"
          "equals" = "Microsoft.Storage/storageAccounts"
        }
      )
    }
    "then" = @{
      "effect" = "audit"
    }
  }
}

Write-Host "Note: To apply these policies, use Azure Portal or CLI:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Example CLI command:"
Write-Host 'az policy assignment create --name "finops-tag-requirement" `' -ForegroundColor Cyan
Write-Host '  --policy "Require tag and its value" `' -ForegroundColor Cyan
Write-Host '  --scope "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}"' -ForegroundColor Cyan
Write-Host ""
