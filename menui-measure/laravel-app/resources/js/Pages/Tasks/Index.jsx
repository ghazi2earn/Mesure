import { Head } from '@inertiajs/react';
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import { useState } from 'react';

export default function TasksIndex({ tasks, filters }) {
    const [search, setSearch] = useState(filters.search || '');
    const [status, setStatus] = useState(filters.status || '');

    const getStatusBadge = (status) => {
        const statusClasses = {
            'nouveau': 'bg-blue-100 text-blue-800',
            'en_attente': 'bg-yellow-100 text-yellow-800',
            'en_execution': 'bg-orange-100 text-orange-800',
            'cloture': 'bg-green-100 text-green-800',
        };

        const statusLabels = {
            'nouveau': 'Nouveau',
            'en_attente': 'En attente',
            'en_execution': 'En exécution',
            'cloture': 'Clôturé',
        };

        return (
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusClasses[status] || 'bg-gray-100 text-gray-800'}`}>
                {statusLabels[status] || status}
            </span>
        );
    };

    return (
        <AuthenticatedLayout
            header={
                <div className="flex justify-between items-center">
                    <h2 className="font-semibold text-xl text-gray-800 leading-tight">
                        Mes Tâches
                    </h2>
                    <a
                        href="/tasks/create"
                        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                    >
                        Nouvelle Tâche
                    </a>
                </div>
            }
        >
            <Head title="Mes Tâches" />

            <div className="py-12">
                <div className="max-w-7xl mx-auto sm:px-6 lg:px-8">
                    <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div className="p-6">
                            {/* Filtres */}
                            <div className="mb-6 flex flex-col sm:flex-row gap-4">
                                <div className="flex-1">
                                    <input
                                        type="text"
                                        placeholder="Rechercher une tâche..."
                                        value={search}
                                        onChange={(e) => setSearch(e.target.value)}
                                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    />
                                </div>
                                <div>
                                    <select
                                        value={status}
                                        onChange={(e) => setStatus(e.target.value)}
                                        className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <option value="">Tous les statuts</option>
                                        <option value="nouveau">Nouveau</option>
                                        <option value="en_attente">En attente</option>
                                        <option value="en_execution">En exécution</option>
                                        <option value="cloture">Clôturé</option>
                                    </select>
                                </div>
                            </div>

                            {/* Liste des tâches */}
                            {tasks.data.length === 0 ? (
                                <div className="text-center py-12">
                                    <div className="text-gray-500 mb-4">
                                        <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                                        </svg>
                                    </div>
                                    <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune tâche trouvée</h3>
                                    <p className="text-gray-500 mb-4">Commencez par créer votre première tâche.</p>
                                    <a
                                        href="/tasks/create"
                                        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                                    >
                                        Créer une tâche
                                    </a>
                                </div>
                            ) : (
                                <div className="space-y-4">
                                    {tasks.data.map((task) => (
                                        <div key={task.id} className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
                                            <div className="flex justify-between items-start">
                                                <div className="flex-1">
                                                    <div className="flex items-center gap-3 mb-2">
                                                        <h3 className="text-lg font-medium text-gray-900">
                                                            <a
                                                                href={`/tasks/${task.id}`}
                                                                className="hover:text-blue-600 transition-colors"
                                                            >
                                                                {task.title}
                                                            </a>
                                                        </h3>
                                                        {getStatusBadge(task.status)}
                                                    </div>
                                                    {task.description && (
                                                        <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                                                            {task.description}
                                                        </p>
                                                    )}
                                                    <div className="flex items-center gap-4 text-sm text-gray-500">
                                                        <span>
                                                            {task.photos_count || 0} photo(s)
                                                        </span>
                                                        <span>
                                                            Créée le {new Date(task.created_at).toLocaleDateString('fr-FR')}
                                                        </span>
                                                    </div>
                                                </div>
                                                <div className="flex gap-2">
                                                    <a
                                                        href={`/tasks/${task.id}`}
                                                        className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                                                    >
                                                        Voir
                                                    </a>
                                                    <a
                                                        href={`/tasks/${task.id}/edit`}
                                                        className="text-gray-600 hover:text-gray-800 text-sm font-medium"
                                                    >
                                                        Modifier
                                                    </a>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}

                            {/* Pagination */}
                            {tasks.data.length > 0 && tasks.links && (
                                <div className="mt-6">
                                    <nav className="flex justify-center">
                                        <div className="flex space-x-1">
                                            {tasks.links.map((link, index) => (
                                                <a
                                                    key={index}
                                                    href={link.url}
                                                    className={`px-3 py-2 text-sm font-medium rounded-md ${
                                                        link.active
                                                            ? 'bg-blue-600 text-white'
                                                            : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'
                                                    } ${!link.url ? 'opacity-50 cursor-not-allowed' : ''}`}
                                                    dangerouslySetInnerHTML={{ __html: link.label }}
                                                />
                                            ))}
                                        </div>
                                    </nav>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </AuthenticatedLayout>
    );
}
