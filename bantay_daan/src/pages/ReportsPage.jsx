import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, doc, getDoc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import StatusBadge from '../components/StatusBadge';
import PriorityBadge from '../components/PriorityBadge';

const TYPES = ['Pothole', 'Flooding', 'Obstruction', 'Road Damage', 'Accident', 'Missing Signage'];

const TYPE_COLORS = {
  'Pothole':        '#F4A261',
  'Flooding':       '#61B4F4',
  'Obstruction':    '#F46161',
  'Road Damage':    '#F4844A',
  'Accident':       '#D94F4F',
  'Missing Signage':'#9B8CF4',
};

export default function ReportsPage() {
  const [reports, setReports]           = useState([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter]     = useState('all');
  const [search, setSearch]             = useState('');
  const [archiving, setArchiving]       = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const q = query(collection(db, 'reports'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, snap => {
      setReports(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    return unsub;
  }, []);

  const handleArchive = async (e, reportId) => {
    e.stopPropagation();
    if (!window.confirm('Archive this report? You can restore it later.')) return;
    setArchiving(reportId);
    try {
      const ref = doc(db, 'reports', reportId);
      const snap = await getDoc(ref);
      if (!snap.exists()) return;
      await setDoc(doc(db, 'archived_reports', reportId), {
        ...snap.data(),
        archivedAt: serverTimestamp(),
      });
      await deleteDoc(ref);
    } catch (err) {
      console.error('Archive error:', err);
    } finally {
      setArchiving(null);
    }
  };

  const filtered = reports.filter(r => {
    const matchStatus = statusFilter === 'all' || r.status === statusFilter;
    const matchType   = typeFilter   === 'all' || r.type   === typeFilter;
    const matchSearch = !search
      || (r.location?.address || '').toLowerCase().includes(search.toLowerCase())
      || (r.type || '').toLowerCase().includes(search.toLowerCase())
      || r.id.toLowerCase().includes(search.toLowerCase());
    return matchStatus && matchType && matchSearch;
  });

  return (
    <div className="flex min-h-screen bg-navy-deep">
      <Sidebar active="reports" />

      <main className="flex-1 p-6 overflow-auto">
        {/* Header */}
        <div className="mb-5 flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-white">All Reports</h2>
            <p className="text-sm text-gray-400 mt-0.5">{reports.length} total reports</p>
          </div>
          <button
            onClick={() => navigate('/archive')}
            className="flex items-center gap-2 text-xs text-gray-400 hover:text-amber transition-colors bg-navy-surface border border-navy-elevated px-3 py-2 rounded-xl"
          >
            <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5">
              <path d="M4 3a2 2 0 100 4h12a2 2 0 100-4H4z" />
              <path fillRule="evenodd" d="M3 8h14v7a2 2 0 01-2 2H5a2 2 0 01-2-2V8zm5 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z" clipRule="evenodd" />
            </svg>
            View Archive
          </button>
        </div>

        {/* Filters */}
        <div className="flex gap-3 mb-5 flex-wrap">
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by type, location, or ID..."
            className="bg-navy-surface text-sm text-white rounded-xl px-4 py-2 border border-navy-elevated focus:border-amber/40 outline-none placeholder:text-gray-600 flex-1 min-w-[200px]"
          />
          <select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            className="bg-navy-surface text-sm text-white rounded-xl px-3 py-2 border border-navy-elevated outline-none cursor-pointer"
          >
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="verified">Verified</option>
            <option value="in_progress">In Progress</option>
            <option value="resolved">Resolved</option>
          </select>
          <select
            value={typeFilter}
            onChange={e => setTypeFilter(e.target.value)}
            className="bg-navy-surface text-sm text-white rounded-xl px-3 py-2 border border-navy-elevated outline-none cursor-pointer"
          >
            <option value="all">All Types</option>
            {TYPES.map(t => <option key={t} value={t}>{t}</option>)}
          </select>
        </div>

        {/* Table */}
        <div className="bg-navy-surface rounded-xl overflow-hidden border border-navy-elevated">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-navy-elevated text-[11px] text-gray-500 font-mono">
                {['ID', 'Type', 'Location', 'Date', 'Priority', 'Status', ''].map(h => (
                  <th key={h} className="text-left px-4 py-3 font-medium">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-sm text-gray-500">
                    No reports match your filters
                  </td>
                </tr>
              ) : filtered.map(r => (
                <tr
                  key={r.id}
                  className="border-b border-navy-elevated last:border-0 cursor-pointer hover:bg-navy-elevated transition-colors group"
                  onClick={() => navigate(`/reports/${r.id}`)}
                >
                  <td className="px-4 py-3 font-mono text-[11px] text-gray-500">{r.id.slice(0, 8)}…</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span
                        className="w-2 h-2 rounded-full flex-shrink-0"
                        style={{ backgroundColor: TYPE_COLORS[r.type] || '#F0F4F8' }}
                      />
                      <span className="text-xs text-white">{r.type}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-400 max-w-[180px] truncate">
                    {r.location?.address || '—'}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500 font-mono whitespace-nowrap">
                    {r.createdAt?.toDate?.().toLocaleDateString('en-PH', {
                      month: 'short', day: 'numeric', year: 'numeric'
                    }) || '—'}
                  </td>
                  <td className="px-4 py-3">
                    <PriorityBadge priority={r.priority || 'low'} />
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={r.status} />
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <span className="text-amber text-xs font-semibold">View →</span>
                      <button
                        onClick={e => handleArchive(e, r.id)}
                        disabled={archiving === r.id}
                        className="text-red-400 hover:text-red-300 transition-colors p-1 rounded-lg hover:bg-red-900/20"
                        title="Archive report"
                      >
                        {archiving === r.id ? (
                          <span className="w-3.5 h-3.5 border border-red-400 border-t-transparent rounded-full animate-spin inline-block" />
                        ) : (
                          <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5">
                            <path d="M4 3a2 2 0 100 4h12a2 2 0 100-4H4z" />
                            <path fillRule="evenodd" d="M3 8h14v7a2 2 0 01-2 2H5a2 2 0 01-2-2V8zm5 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z" clipRule="evenodd" />
                          </svg>
                        )}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}