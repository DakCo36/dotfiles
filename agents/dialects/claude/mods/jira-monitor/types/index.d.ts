export type JiraIssue = { key: string; status: string; summary: string }

export type JiraSnapshot = {
  issues: JiraIssue[]
  fetchedAt: number | null
  error: string | null
}

declare module 'claude-code' {
  interface PluginState {
    'jira-monitor': { snapshot: JiraSnapshot }
  }
}
