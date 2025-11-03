export interface StatusResponse {
  status: string
  version: string
  git_commit?: string
  git_branch?: string
  gps_precision?: string
  max_tracked_objects?: number
}

export interface Source {
  source_id: string
  source_type: string
  is_available?: boolean
}

export interface SourcesResponse {
  sources: Source[]
}

export interface UpdaterStatusResponse {
  enabled: boolean
  is_running?: boolean
  repository?: string
  branch?: string
  poll_interval_minutes?: number
  last_commit_sha?: string
  last_check?: string
  next_check?: string
}

