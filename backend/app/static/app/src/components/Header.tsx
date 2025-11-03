import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api'

export function Header() {
  const [isOnline, setIsOnline] = useState<boolean | null>(null)

  useEffect(() => {
    const checkStatus = async () => {
      try {
        await api.getStatus()
        setIsOnline(true)
      } catch {
        setIsOnline(false)
      }
    }

    checkStatus()
    const interval = setInterval(checkStatus, 30000)
    return () => clearInterval(interval)
  }, [])

  return (
    <header className="bg-surface/90 backdrop-blur border-b border-token sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-elev rounded-lg flex items-center justify-center border border-token">
              <i className="fas fa-satellite-dish text-muted text-sm"></i>
            </div>
            <div>
              <h1 className="text-base font-semibold">ERMES</h1>
              <p className="text-xs text-muted">Tracking & Geolocalizzazione</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className={`flex items-center gap-2 px-3 py-1.5 rounded-lg border border-token bg-elev ${
              isOnline === null 
                ? 'text-muted' 
                : isOnline 
                ? 'text-green-600 dark:text-green-400' 
                : 'text-red-600 dark:text-red-400'
            }`}>
              <i className={`fas ${
                isOnline === null 
                  ? 'fa-circle-notch fa-spin' 
                  : isOnline 
                  ? 'fa-circle' 
                  : 'fa-times-circle'
              } text-xs`}></i>
              <span className="text-xs font-medium">
                {isOnline === null ? 'Caricamento...' : isOnline ? 'Online' : 'Offline'}
              </span>
            </div>
            <Link 
              to="/docs"
              className="inline-flex items-center gap-2 h-9 px-3 rounded-lg border border-token bg-surface hover:bg-elev transition"
            >
              <i className="fas fa-book text-xs text-muted"></i>
              <span className="text-sm">API Docs</span>
            </Link>
          </div>
        </div>
      </div>
    </header>
  )
}

