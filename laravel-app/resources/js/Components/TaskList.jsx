import { Link } from '@inertiajs/react';

const statusColors = {
    'nouveau': 'bg-blue-100 text-blue-800',
    'en_attente': 'bg-yellow-100 text-yellow-800',
    'en_execution': 'bg-green-100 text-green-800',
    'cloture': 'bg-gray-100 text-gray-800'
};

const statusLabels = {
    'nouveau': 'Nouveau',
    'en_attente': 'En attente',
    'en_execution': 'En exécution',
    'cloture': 'Clôturé'
};

export default function TaskList({ tasks }) {
    return (
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
                {tasks.map((task) => (
                    <li key={task.id}>
                        <Link
                            href={`/tasks/${task.id}`}
                            className="block hover:bg-gray-50 px-4 py-4 sm:px-6"
                        >
                            <div className="flex items-center justify-between">
                                <div className="flex-1 min-w-0">
                                    <p className="text-sm font-medium text-indigo-600 truncate">
                                        {task.title}
                                    </p>
                                    <p className="text-sm text-gray-500">
                                        {task.description || 'Aucune description'}
                                    </p>
                                    <div className="mt-2 flex items-center text-sm text-gray-500">
                                        <span>Créé le {new Date(task.created_at).toLocaleDateString('fr-FR')}</span>
                                        {task.photos_count > 0 && (
                                            <span className="ml-4">
                                                {task.photos_count} photo{task.photos_count > 1 ? 's' : ''}
                                            </span>
                                        )}
                                    </div>
                                </div>
                                <div className="ml-4 flex-shrink-0">
                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusColors[task.status]}`}>
                                        {statusLabels[task.status]}
                                    </span>
                                </div>
                            </div>
                        </Link>
                    </li>
                ))}
            </ul>
            
            {tasks.length === 0 && (
                <div className="text-center py-12">
                    <p className="text-gray-500">Aucune tâche trouvée</p>
                    <Link
                        href="/tasks/create"
                        className="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700"
                    >
                        Créer une nouvelle tâche
                    </Link>
                </div>
            )}
        </div>
    );
}