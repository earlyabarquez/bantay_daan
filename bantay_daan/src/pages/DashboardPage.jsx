import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, limit } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import StatusBadge from '../components/StatusBadge';

const TYPE_COLORS = {
  'Pothole':        '#F4A261',
  'Flooding':       '#61B4F4',
  'Obstruction':    '#F46161',
  'Road Damage':    '#F4844A',
  'Accident':       '#D94F4F',
  'Missing Signage':'#9B8CF4',
};

export default function DashboardPage() {
  const [reports, setReports] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'reports'), snap => {
      setReports(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    return unsub;
  }, []);

  const count = (status) => reports.filter(r => r.status === status).length;
  const highPriority = reports.filter(r => r.priority === 'high').length;

  const stats = [
    { label: 'Total Reports',  value: reports.length,      color: 'text-white',       icon: '📋', accent: '#F0F4F8' },
    { label: 'Pending',        value: count('pending'),     color: 'text-yellow-400',  icon: '⏳', accent: '#F4C261' },
    { label: 'Verified',       value: count('verified'),    color: 'text-blue-400',    icon: '✅', accent: '#61B4F4' },
    { label: 'In Progress',    value: count('in_progress'), color: 'text-violet-400',  icon: '🔧', accent: '#9B8CF4' },
    { label: 'Resolved',       value: count('resolved'),    color: 'text-green-400',   icon: '✔', accent: '#61F4A2' },
    { label: 'High Priority',  value: highPriority,         color: 'text-red-400',     icon: '🔴', accent: '#F46161' },
  ];

  // Type breakdown
  const typeBreakdown = Object.entries(TYPE_COLORS).map(([type, color]) => ({
    type,
    color,
    count: reports.filter(r => r.type === type).length,
  }));

  // Recent 5 reports
  const recent = [...reports]
    .sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0))
    .slice(0, 5);

  return (
    <div className="flex min-h-screen bg-navy-deep">
      <Sidebar active="dashboard" />

      <main className="flex-1 p-6 overflow-auto">
        {/* Header */}
        <div className="mb-6">
          <h2 className="text-xl font-bold text-white">Dashboard</h2>
          <p className="text-sm text-gray-400 mt-0.5">Real-time overview of all road reports</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          {stats.map(s => (
            <div key={s.label} className="bg-navy-surface rounded-xl p-4 border border-navy-elevated hover:border-amber/20 transition-colors">
              <div className="flex items-center justify-between mb-3">
                <p className="text-xs text-gray-400 font-medium">{s.label}</p>
                <span className="text-base">{s.icon}</span>
              </div>
              <p className={`text-3xl font-bold font-mono ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-3 gap-6">
          {/* Recent Reports */}
          <div className="col-span-2 bg-navy-surface rounded-xl border border-navy-elevated overflow-hidden">
            <div className="px-4 py-3 border-b border-navy-elevated flex items-center justify-between">
              <p className="text-sm font-semibold text-white">Recent Reports</p>
              <button
                onClick={() => navigate('/reports')}
                className="text-xs text-amber hover:opacity-80"
              >
                View all →
              </button>
            </div>
            <table className="w-full text-sm">
              <thead>
                <tr className="text-[11px] text-gray-500 font-mono border-b border-navy-elevated">
                  {['Type', 'Location', 'Status', ''].map(h => (
                    <th key={h} className="text-left px-4 py-2.5 font-medium">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {recent.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                      No reports yet
                    </td>
                  </tr>
                ) : recent.map(r => (
                  <tr
                    key={r.id}
                    className="border-b border-navy-elevated last:border-0 cursor-pointer hover:bg-navy-elevated transition-colors"
                    onClick={() => navigate(`/reports/${r.id}`)}
                  >
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <span
                          className="w-2 h-2 rounded-full flex-shrink-0"
                          style={{ backgroundColor: TYPE_COLORS[r.type] || '#F0F4F8' }}
                        />
                        <span className="text-xs text-white">{r.type}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-400 max-w-[140px] truncate">
                      {r.location?.address || '—'}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={r.status} />
                    </td>
                    <td className="px-4 py-3 text-amber text-xs font-semibold">View</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Type Breakdown */}
          <div className="bg-navy-surface rounded-xl border border-navy-elevated overflow-hidden">
            <div className="px-4 py-3 border-b border-navy-elevated">
              <p className="text-sm font-semibold text-white">By Type</p>
            </div>
            <div className="p-4 space-y-3">
              {typeBreakdown.map(({ type, color, count }) => (
                <div key={type}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-xs text-gray-300">{type}</span>
                    <span className="text-xs font-mono font-bold" style={{ color }}>{count}</span>
                  </div>
                  <div className="h-1.5 bg-navy-elevated rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: reports.length > 0 ? `${(count / reports.length) * 100}%` : '0%',
                        backgroundColor: color,
                      }}
                    />
                  </div>
                </div>
              ))}
              {reports.length === 0 && (
                <p className="text-xs text-gray-500 text-center py-4">No data yet</p>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
