'use client';

import { useState, useEffect } from 'react';

interface User {
  id: number;
  name: string;
  created_at: string;
}

export default function Home() {
  const [users, setUsers] = useState<User[]>([]);
  const [dbStatus, setDbStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mounted, setMounted] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  useEffect(() => {
    setMounted(true);
    fetchData();
  }, []);

  const fetchData = async (currentRetry = 0) => {
    const maxRetries = 5;
    const retryDelay = 2000; // 2 seconds

    try {
      setLoading(true);
      setError(null);
      setRetryCount(currentRetry);

      const dbRes = await fetch('/api/test-db');
      if (!dbRes.ok) throw new Error('Backend not ready');
      const dbData = await dbRes.json();
      setDbStatus(dbData);

      const usersRes = await fetch('/api/users');
      if (!usersRes.ok) throw new Error('Backend not ready');
      const usersData = await usersRes.json();
      setUsers(usersData);

      setLoading(false);
      setRetryCount(0);
    } catch (err) {
      if (currentRetry < maxRetries) {
        // Retry after delay
        console.log(`Retry ${currentRetry + 1}/${maxRetries} in ${retryDelay}ms...`);
        setTimeout(() => fetchData(currentRetry + 1), retryDelay);
      } else {
        setError(err instanceof Error ? err.message : 'Failed to fetch data after multiple retries');
        setLoading(false);
      }
    }
  };

  if (!mounted) {
    return null;
  }

  return (
    <main className="min-h-screen bg-slate-50 py-12 px-4">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex items-center justify-center gap-3 mb-4">
            <span className="text-5xl">🚀</span>
            <h1 className="text-4xl font-bold text-slate-900">
              Kubernetes Multi-Tier App
            </h1>
          </div>
          <p className="text-slate-600 text-lg">
            Next.js → Go → PostgreSQL
          </p>
        </div>

        {/* Status Grid */}
        <div className="grid md:grid-cols-2 gap-6 mb-6">
          {/* Database Status */}
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
            <div className="flex items-center gap-2 mb-4">
              <span className="text-2xl">📊</span>
              <h2 className="text-xl font-semibold text-slate-900">
                Database Status
              </h2>
            </div>
            {loading ? (
              <div className="flex items-center gap-2 text-slate-500">
                <div className="w-4 h-4 border-2 border-slate-300 border-t-slate-600 rounded-full animate-spin"></div>
                <span>
                  {retryCount > 0
                    ? `Connecting... (Retry ${retryCount}/5)`
                    : 'Connecting...'}
                </span>
              </div>
            ) : error ? (
              <div className="space-y-3">
                <div className="flex items-center gap-2 text-red-600">
                  <span>❌</span>
                  <span className="text-sm">{error}</span>
                </div>
                <button
                  onClick={() => fetchData()}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Retry Connection
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="flex items-start gap-2">
                  <span className="text-green-500 mt-0.5">✓</span>
                  <div>
                    <p className="text-green-700 font-medium">
                      {dbStatus?.message}
                    </p>
                    <p className="text-slate-500 text-sm mt-1">
                      {new Date(dbStatus?.timestamp).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Quick Stats */}
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
            <div className="flex items-center gap-2 mb-4">
              <span className="text-2xl">📈</span>
              <h2 className="text-xl font-semibold text-slate-900">
                Quick Stats
              </h2>
            </div>
            {loading ? (
              <div className="flex items-center gap-2 text-slate-500">
                <div className="w-4 h-4 border-2 border-slate-300 border-t-slate-600 rounded-full animate-spin"></div>
                <span>Loading...</span>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-slate-600">Total Users</span>
                  <span className="text-2xl font-bold text-indigo-600">
                    {users.length}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-600">Pods Running</span>
                  <span className="text-2xl font-bold text-green-600">3</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-600">Services</span>
                  <span className="text-2xl font-bold text-blue-600">3</span>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Users List */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
          <div className="flex items-center gap-2 mb-6">
            <span className="text-2xl">👥</span>
            <h2 className="text-xl font-semibold text-slate-900">
              Users from Database
            </h2>
          </div>
          {loading ? (
            <div className="flex items-center gap-2 text-slate-500">
              <div className="w-4 h-4 border-2 border-slate-300 border-t-slate-600 rounded-full animate-spin"></div>
              <span>Loading users...</span>
            </div>
          ) : error ? (
            <div className="text-red-600 flex items-center gap-2">
              <span>❌</span>
              <span>{error}</span>
            </div>
          ) : (
            <div className="grid gap-3">
              {users.map((user, index) => (
                <div
                  key={user.id}
                  className="flex items-center justify-between p-4 rounded-lg bg-slate-50 hover:bg-slate-100 transition-colors border border-slate-200"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-semibold">
                      {index + 1}
                    </div>
                    <div>
                      <p className="font-medium text-slate-900">{user.name}</p>
                      <p className="text-sm text-slate-500">
                        ID: {user.id} • {new Date(user.created_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <div className="text-green-500">✓</div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="mt-12 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-slate-100 rounded-full text-sm text-slate-600">
            <span>⚡</span>
            <span>Built by Jabril • Platform Engineering</span>
          </div>
        </div>
      </div>
    </main>
  );
}