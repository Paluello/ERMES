import { ReactNode } from 'react'

interface InfoCardProps {
  title: string
  icon: string
  children: ReactNode
}

export function InfoCard({ title, icon, children }: InfoCardProps) {
  return (
    <div className="bg-elev rounded-xl shadow-subtle border border-token overflow-hidden">
      <div className={`p-4 border-b border-token`}>
        <div className="flex items-center gap-3">
          <div className={`w-8 h-8 bg-surface rounded-md flex items-center justify-center border border-token`}>
            <i className={`${icon} text-muted text-sm`}></i>
          </div>
          <h2 className="text-base font-semibold">{title}</h2>
        </div>
      </div>
      <div className="p-5">
        {children}
      </div>
    </div>
  )
}

