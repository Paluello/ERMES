import { useEffect, useState } from 'react'
import { api } from '../api'
import type { Source } from '../types'
import { InfoCard } from './InfoCard'

function Badge({ text, type }: { text: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }) {
  const colors: Record<string, string> = {
    success: 'text-green-600 dark:text-green-400 border-green-200/50 dark:border-green-900/40',
    warning: 'text-yellow-700 dark:text-yellow-400 border-yellow-200/50 dark:border-yellow-900/40',
    danger: 'text-red-600 dark:text-red-400 border-red-200/50 dark:border-red-900/40',
    info: 'text-blue-600 dark:text-blue-400 border-blue-200/50 dark:border-blue-900/40',
    primary: 'text-muted border-token'
  }
  return (
    <span className={`inline-flex items-center h-6 px-2 rounded-md text-xs font-medium bg-elev border ${colors[type]}`}>
      {text}
    </span>
  )
}

function SourceCard({ source }: { source: Source }) {
  const statusColor = source.is_available !== false ? 'success' : 'danger'
  const statusText = source.is_available !== false ? 'Attiva' : 'Inattiva'

  return (
    <div className="bg-elev rounded-xl p-5 border border-token hover:bg-surface transition">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center space-x-3">
          <div className="w-9 h-9 bg-surface rounded-lg flex items-center justify-center border border-token">
            <i className="fas fa-signal text-muted text-sm"></i>
          </div>
          <div>
            <h3 className="font-semibold">{source.source_id || 'N/A'}</h3>
            <p className="text-xs text-muted">{source.source_type || 'N/A'}</p>
          </div>
        </div>
        <Badge text={statusText} type={statusColor} />
      </div>
      <div className="mt-3 pt-3 border-t border-token">
        <div className="flex items-center space-x-2 text-xs text-muted">
          <i className="fas fa-fingerprint"></i>
          <code className="bg-surface px-2 py-1 rounded border border-token">{source.source_id || 'N/A'}</code>
        </div>
      </div>
    </div>
  )
}

interface SourcesListProps {
  onRefresh?: () => void
}

export function SourcesList({ onRefresh }: SourcesListProps) {
  const [sources, setSources] = useState<Source[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [refreshing, setRefreshing] = useState(false)

  const loadData = async () => {
    try {
      const data = await api.getSources()
      setSources(data.sources || [])
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Errore sconosciuto')
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  useEffect(() => {
    loadData()
    const interval = setInterval(loadData, 30000)
    return () => clearInterval(interval)
  }, [])

  const handleRefresh = () => {
    setRefreshing(true)
    loadData()
    if (onRefresh) onRefresh()
  }

  return (
    <InfoCard
      title="Sorgenti Attive"
      icon="fas fa-broadcast-tower"
    >
      <div className="mb-4 flex justify-end">
        <button
          onClick={handleRefresh}
          disabled={refreshing}
          className="inline-flex items-center gap-2 h-9 px-3 rounded-lg border border-token bg-surface hover:bg-elev transition text-sm disabled:opacity-50"
        >
          <i className={`fas fa-sync-alt ${refreshing ? 'fa-spin' : ''}`}></i>
          <span>Aggiorna</span>
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-token"></div>
        </div>
      ) : error ? (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start space-x-3">
          <i className="fas fa-exclamation-circle text-red-600 mt-0.5"></i>
          <div>
            <p className="text-sm font-medium text-red-900">Errore</p>
            <p className="text-sm text-red-700 mt-1">{error}</p>
          </div>
        </div>
      ) : sources.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-12 text-gray-400">
          <i className="fas fa-inbox text-5xl mb-4 opacity-50"></i>
          <p className="text-sm font-medium">Nessuna sorgente attiva</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {sources.map((source) => (
            <SourceCard key={source.source_id} source={source} />
          ))}
        </div>
      )}
    </InfoCard>
  )
}

