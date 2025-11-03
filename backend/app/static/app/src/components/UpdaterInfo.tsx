import { useEffect, useState } from 'react'
import { api } from '../api'
import type { UpdaterStatusResponse } from '../types'
import { InfoCard } from './InfoCard'

function InfoItem({ label, value, icon }: { label: string; value: React.ReactNode; icon?: string }) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex items-center space-x-2 text-gray-600">
        {icon && <i className={`${icon} text-sm`}></i>}
        <span className="text-sm font-medium">{label}</span>
      </div>
      <div className="text-sm font-semibold text-gray-900">{value}</div>
    </div>
  )
}

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

export function UpdaterInfo() {
  const [data, setData] = useState<UpdaterStatusResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadData = async () => {
      try {
        const status = await api.getUpdaterStatus()
        setData(status)
        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Errore sconosciuto')
      }
    }

    loadData()
  }, [])

  if (error) {
    return (
      <InfoCard
        title="Auto-Updater"
        icon="fas fa-sync-alt"
      >
        <div className="flex flex-col items-center justify-center py-12 text-gray-400">
          <i className="fas fa-exclamation-triangle text-5xl mb-4 opacity-50"></i>
          <p className="text-sm font-medium">Auto-updater non disponibile</p>
        </div>
      </InfoCard>
    )
  }

  if (!data) {
    return (
      <InfoCard
        title="Auto-Updater"
        icon="fas fa-sync-alt"
      >
        <div className="flex items-center justify-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
        </div>
      </InfoCard>
    )
  }

  if (!data.enabled) {
    return (
      <InfoCard
        title="Auto-Updater"
        icon="fas fa-sync-alt"
      >
        <div className="flex flex-col items-center justify-center py-12 text-gray-400">
          <i className="fas fa-ban text-5xl mb-4 opacity-50"></i>
          <p className="text-sm font-medium">Auto-updater non configurato</p>
        </div>
      </InfoCard>
    )
  }

  return (
    <InfoCard
      title="Auto-Updater"
      icon="fas fa-sync-alt"
    >
      <div className="space-y-4">
        <InfoItem 
          label="Stato" 
          value={<Badge text="Attivo" type="success" />} 
          icon="fas fa-power-off"
        />
        {data.repository && (
          <InfoItem label="Repository" value={data.repository} icon="fas fa-database" />
        )}
        {data.branch && (
          <InfoItem label="Branch" value={data.branch} icon="fas fa-code-branch" />
        )}
        {data.poll_interval_minutes && (
          <InfoItem 
            label="Intervallo" 
            value={`${data.poll_interval_minutes} minuti`} 
            icon="fas fa-clock"
          />
        )}
        {data.last_commit_sha && (
          <InfoItem 
            label="Ultimo commit" 
            value={<Badge text={data.last_commit_sha} type="info" />} 
            icon="fas fa-history"
          />
        )}
      </div>
    </InfoCard>
  )
}

