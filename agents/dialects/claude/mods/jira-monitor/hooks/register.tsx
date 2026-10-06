import { atom, read, update } from 'claude-code'
import type { EngineInterface, PluginOptions, Register } from 'claude-code'

import type { JiraIssue, JiraSnapshot } from '../types'

const TOGGLE_CMD = 'jira-monitor'
const REFRESH_CMD = 'jira-refresh'
const PANE = 'jira-monitor'
const TITLE = 'Tasks'

const EMPTY: JiraSnapshot = { issues: [], fetchedAt: null, error: null }
const snapshot = atom({ plugin: 'jira-monitor', key: 'snapshot' } as const, EMPTY)

type JiraSettings = { baseUrl: string; email: string; apiToken: string; jql: string; maxResults: number }

type SearchResponse = {
  issues?: { key: string; fields: { summary: string; status: { name: string } } }[]
  errorMessages?: string[]
}

const optionText = (options: PluginOptions, name: string) => String(options[name] ?? '').trim()

const clampOr = (options: PluginOptions, name: string, min: number, max: number, fallback: number) => {
  const value = Number(options[name])
  return Number.isFinite(value) ? Math.min(max, Math.max(min, value)) : fallback
}

const toIssues = (body: SearchResponse): JiraIssue[] =>
  (body.issues ?? []).map(issue => ({
    key: issue.key,
    status: issue.fields.status.name,
    summary: issue.fields.summary,
  }))

async function resolveSettings($: EngineInterface, options: PluginOptions): Promise<JiraSettings> {
  return {
    baseUrl: optionText(options, 'baseUrl').replace(/\/+$/, ''),
    email: optionText(options, 'email'),
    apiToken: optionText(options, 'apiToken') || ((await $.env.get('JIRA_API_TOKEN')) ?? ''),
    jql: optionText(options, 'jql'),
    maxResults: Math.floor(clampOr(options, 'maxResults', 1, 100, 30)),
  }
}

async function refresh($: EngineInterface, options: PluginOptions) {
  const settings = await resolveSettings($, options)
  if (!settings.baseUrl || !settings.email || !settings.apiToken) {
    await update($, snapshot, prev => ({ ...prev, error: 'Set base URL, email and API token in /config (jira-monitor)' }))
    return
  }

  const query = new URLSearchParams({
    jql: settings.jql,
    fields: 'summary,status',
    maxResults: String(settings.maxResults),
  })
  try {
    const { ok, status, text } = await $.http.fetch(`${settings.baseUrl}/rest/api/3/search/jql?${query}`, {
      headers: {
        Authorization: `Basic ${btoa(`${settings.email}:${settings.apiToken}`)}`,
        Accept: 'application/json',
      },
    })
    const body = JSON.parse(text) as SearchResponse
    const next: Partial<JiraSnapshot> = ok
      ? { issues: toIssues(body), fetchedAt: Date.now(), error: null }
      : { error: `HTTP ${status}: ${body.errorMessages?.[0] ?? 'request failed'}` }
    await update($, snapshot, prev => ({ ...prev, ...next }))
  } catch (err) {
    await update($, snapshot, prev => ({ ...prev, error: String(err) }))
  }
}

export const register: Register = (on, options) => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: TOGGLE_CMD, description: 'Show(or Off) my open Jira issues in a side pane' })
    await $.command.register({ name: REFRESH_CMD, description: 'Refresh my Jira issues'})
    void $.ui.open({ id: PANE, title: TITLE })
    void refresh($, options)
    const refreshIntervalMs = clampOr(options, 'refreshMinutes', 1, 10, 3) * 60 * 1000
    $.clock.every(refreshIntervalMs, () => refresh($, options))
    return next(e)
  })

  on('command.run', { command: TOGGLE_CMD }, async $ => {
    const isOpen = (await $.ui.panes()).some(pane => pane.id === PANE)
    if (isOpen) {
      await $.ui.close({id: PANE})
      return { text: 'Jira pane closed.'}
    }
    
    await $.ui.open({ id: PANE, title: TITLE })
    await refresh($, options) // refresh before open
    const { issues, error } = await read($, snapshot)
    return { text: error ? `Jira refresh failed: ${error}` : `${issues.length} open Jira issues.` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const { issues, fetchedAt, error } = await read($, snapshot)
    const room = Math.max(1, Math.floor(((e.viewport?.rows ?? 24) - 4) / 2))
    const updated = fetchedAt ? new Date(fetchedAt).toTimeString().slice(0, 5) : '—'

    return (
      <Box flexDirection="column">
        <Text dimColor>
          {issues.length} open · updated {updated}
        </Text>
        {error && <Text color="red">{error}</Text>}
        {fetchedAt === null && !error && <Text dimColor>Loading…</Text>}
        {issues.slice(0, room).map(issue => (
          <Box flexDirection="column">
            <Text>
              <Text bold color="cyan">{issue.key}</Text> <Text dimColor>[{issue.status}]</Text>
            </Text>
            <Text wrap="truncate-end">  {issue.summary}</Text>
          </Box>
        ))}
      </Box>
    )
  })
}
