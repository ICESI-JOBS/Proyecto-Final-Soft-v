param location string = 'eastus'
param environmentTag string = 'dev'
param projectName string = 'ecommerce-app'

// Variables para Cost Management
var costManagementMetricsDisplayName = '${projectName}-cost-monitoring'
var budgetDisplayName = '${projectName}-monthly-budget'
var alertActionGroupName = '${projectName}-cost-alerts'

// Alert Action Group para notificaciones de costos
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: alertActionGroupName
  location: 'global'
  tags: {
    environment: environmentTag
    project: projectName
  }
  properties: {
    groupShortName: 'CostAlert'
    enabled: true
    emailReceivers: [
      {
        name: 'FinOps Team'
        emailAddress: 'finops@icesi.edu.co'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Budget Alert para control de costos
resource budgetAlert 'Microsoft.CostManagement/budgets@2023-03-01' = {
  scope: resourceGroup()
  name: budgetDisplayName
  properties: {
    displayName: budgetDisplayName
    description: 'Monthly budget for ${projectName} with automatic alerts'
    category: 'Cost'
    amount: 1000 // USD monthly budget
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: utcNow('yyyy-MM-01')
      endDate: '2025-12-31'
    }
    filter: {
      tags: {
        name: 'environment'
        operator: 'In'
        values: [
          environmentTag
        ]
      }
    }
    notifications: {
      notificationByResourceGroupEnabled: false
      notificationsByResourceEnabled: false
    }
    etag: ''
  }
}

// Diagnostic Settings para enviar logs de costos a Log Analytics
var logAnalyticsWorkspaceName = '${projectName}-law'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    environment: environmentTag
    project: projectName
  }
}

// Outputs
output budgetId string = budgetAlert.id
output actionGroupId string = actionGroup.id
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
