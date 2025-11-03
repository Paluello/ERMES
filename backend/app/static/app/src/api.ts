import type { StatusResponse, SourcesResponse, UpdaterStatusResponse } from './types'

const API_BASE = '/api'

export const api = {
  async get<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${API_BASE}${endpoint}`)
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    return await response.json()
  },

  async getStatus(): Promise<StatusResponse> {
    return this.get<StatusResponse>('/status')
  },

  async getSources(): Promise<SourcesResponse> {
    return this.get<SourcesResponse>('/sources')
  },

  async getUpdaterStatus(): Promise<UpdaterStatusResponse> {
    return this.get<UpdaterStatusResponse>('/update/polling/status')
  },
}

