import { useEffect, useState } from 'react'
import { Header } from '../components/Header'
import { StatCard } from '../components/StatCard'
import { SystemInfo } from '../components/SystemInfo'
import { VersionInfo } from '../components/VersionInfo'
import { UpdaterInfo } from '../components/UpdaterInfo'
import { SourcesList } from '../components/SourcesList'
import { api } from '../api'
import type { StatusResponse } from '../types'

export function Dashboard() {
  const [stats, setStats] = useState<StatusResponse | null>(null)
  const [sourcesCount, setSourcesCount] = useState<number>(0)

  const loadStats = async () => {
    try {
      const status = await api.getStatus()
      setStats(status)
      
      const sources = await api.getSources()
      setSourcesCount(sources.sources?.length || 0)
    } catch (err) {
      console.error('Errore caricamento statistiche:', err)
    }
  }

  useEffect(() => {
    loadStats()
    const interval = setInterval(loadStats, 30000)
    return () => clearInterval(interval)
  }, [])

  const handleSourcesRefresh = () => {
    loadStats()
  }

  return (
    <div className="min-h-full bg-surface">
      <Header />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Overview */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            icon="fas fa-broadcast-tower"
            iconBg="bg-surface"
            iconColor="text-muted"
            value={sourcesCount}
            label="Sorgenti"
            description="Attive nel sistema"
          />
          <StatCard
            icon="fas fa-check-circle"
            iconBg="bg-surface"
            iconColor="text-muted"
            value={stats?.status || '-'}
            label="Stato"
            description="Sistema operativo"
          />
          <StatCard
            icon="fas fa-map-marker-alt"
            iconBg="bg-surface"
            iconColor="text-muted"
            value={stats?.gps_precision || '-'}
            label="GPS"
            description="Precisione"
          />
          <StatCard
            icon="fas fa-eye"
            iconBg="bg-surface"
            iconColor="text-muted"
            value={stats?.max_tracked_objects || '-'}
            label="Oggetti"
            description="Massimo tracciati"
          />
        </div>

        {/* Cards Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          <SystemInfo />
          <VersionInfo />
          <UpdaterInfo />
        </div>

        {/* Sources Card */}
        <SourcesList onRefresh={handleSourcesRefresh} />
      </main>
    </div>
  )
}

