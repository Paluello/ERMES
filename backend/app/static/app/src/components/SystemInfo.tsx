import { useEffect, useState } from 'react'
import { api } from '../api'
import type { StatusResponse } from '../types'
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

export function SystemInfo() {
  const [data, setData] = useState<StatusResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadData = async () => {
      try {
        const status = await api.getStatus()
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
        title="Sistema"
        icon="fas fa-server"
      >
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start space-x-3">
          <i className="fas fa-exclamation-circle text-red-600 mt-0.5"></i>
          <div>
            <p className="text-sm font-medium text-red-900">Errore</p>
            <p className="text-sm text-red-700 mt-1">{error}</p>
          </div>
        </div>
      </InfoCard>
    )
  }

  if (!data) {
    return (
      <InfoCard
        title="Sistema"
        icon="fas fa-server"
      >
        <div className="flex items-center justify-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      </InfoCard>
    )
  }

  return (
    <InfoCard
      title="Sistema"
      icon="fas fa-server"
    >
      <div className="space-y-4">
        <InfoItem 
          label="Stato" 
          value={<Badge text={data.status || 'N/A'} type="success" />} 
          icon="fas fa-check-circle"
        />
        <InfoItem 
          label="Precisione GPS" 
          value={data.gps_precision || 'N/A'} 
          icon="fas fa-map-marker-alt"
        />
        <InfoItem 
          label="Oggetti max" 
          value={String(data.max_tracked_objects || 'N/A')} 
          icon="fas fa-eye"
        />
      </div>
    </InfoCard>
  )
}

