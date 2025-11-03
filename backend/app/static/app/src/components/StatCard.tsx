interface StatCardProps {
  icon: string
  iconBg: string
  iconColor: string
  value: string | number
  label: string
  description: string
}

export function StatCard({ icon, iconBg, iconColor, value, label, description }: StatCardProps) {
  return (
    <div className="bg-elev rounded-xl p-5 shadow-subtle border border-token transition">
      <div className="flex items-center justify-between mb-1.5">
        <div className={`w-10 h-10 ${iconBg} rounded-lg flex items-center justify-center border border-token`}>
          <i className={`${icon} ${iconColor} text-sm`}></i>
        </div>
        <div className="text-right">
          <div className="text-2xl font-semibold">{value}</div>
          <div className="text-xs text-muted">{label}</div>
        </div>
      </div>
      <div className="text-xs text-muted mt-2">{description}</div>
    </div>
  )
}

