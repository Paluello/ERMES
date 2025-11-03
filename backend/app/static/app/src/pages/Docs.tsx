import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import SwaggerUI from 'swagger-ui-react'
import 'swagger-ui-react/swagger-ui.css'
import '../styles/swagger-custom.css'

export function Docs() {
  const [openApiSpec, setOpenApiSpec] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Carica lo schema OpenAPI da FastAPI
    fetch('/openapi.json')
      .then(res => {
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`)
        }
        return res.json()
      })
      .then(data => {
        setOpenApiSpec(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message)
        setLoading(false)
      })
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen bg-surface">
        <div className="flex items-center justify-center h-screen font-sans">
          <div className="text-center">
            <div className="w-10 h-10 border-4 border-token border-t-gray-800 rounded-full animate-spin mx-auto mb-4"></div>
            <p className="text-muted">Caricamento documentazione API...</p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center">
        <div className="bg-elev border border-token rounded-xl p-6 max-w-md">
          <h2 className="text-lg font-semibold mb-2">Errore nel caricamento</h2>
          <p className="text-muted mb-4">{error}</p>
          <p className="text-sm text-muted">
            Assicurati che il server sia in esecuzione e che l'endpoint <code className="bg-surface px-1 rounded border border-token">/openapi.json</code> sia accessibile.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-surface">
      {/* Header */}
      <div className="bg-surface border-b border-token">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 bg-elev rounded-lg flex items-center justify-center border border-token">
                <i className="fas fa-book text-muted text-sm"></i>
              </div>
              <div>
                <h1 className="text-base font-semibold">ERMES API Documentation</h1>
                <p className="text-xs text-muted">Documentazione interattiva</p>
              </div>
            </div>
            <Link
              to="/"
              className="inline-flex items-center gap-2 h-9 px-3 rounded-lg border border-token bg-surface hover:bg-elev transition text-sm"
            >
              <i className="fas fa-home text-xs text-muted"></i>
              <span>Dashboard</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Swagger UI */}
      <div className="swagger-container">
        <SwaggerUI 
          spec={openApiSpec}
          deepLinking={true}
          displayRequestDuration={true}
          filter={true}
          showExtensions={true}
          showCommonExtensions={true}
          tryItOutEnabled={true}
          docExpansion="list"
          syntaxHighlight={{
            activate: true,
            theme: "agate"
          }}
          supportedSubmitMethods={['get', 'post', 'put', 'delete', 'patch']}
        />
      </div>
    </div>
  )
}

