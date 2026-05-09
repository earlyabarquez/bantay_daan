const COLORS = {
  pending:     'bg-yellow-900/30 text-yellow-400 border-yellow-400/40',
  verified:    'bg-blue-900/30   text-blue-400   border-blue-400/40',
  in_progress: 'bg-violet-900/30 text-violet-400 border-violet-400/40',
  resolved:    'bg-green-900/30  text-green-400  border-green-400/40',
};

const LABELS = {
  pending:     'Pending',
  verified:    'Verified',
  in_progress: 'In Progress',
  resolved:    'Resolved',
}

const DOTS = {
  pending:     'bg-yellow-400',
  verified:    'bg-blue-400',
  in_progress: 'bg-violet-400',
  resolved:    'bg-green-400',
};

export default function StatusBadge({ status }) {
  return (
    <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full border ${COLORS[status] || 'bg-gray-900/30 text-gray-400 border-gray-400/40'}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${DOTS[status] || 'bg-gray-400'}`} />
      {LABELS[status] || status}
    </span>
  );
}
