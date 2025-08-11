import AppLayout from '../Layouts/AppLayout';
import TaskList from '../Components/TaskList';
import { Link } from '@inertiajs/react';

export default function Dashboard({ tasks, stats }) {
    return (
        <AppLayout title="Tableau de bord">
            <div className="px-4 sm:px-6 lg:px-8">
                {/* En-tête */}
                <div className="sm:flex sm:items-center">
                    <div className="sm:flex-auto">
                        <h1 className="text-2xl font-semibold text-gray-900">Tableau de bord</h1>
                        <p className="mt-2 text-sm text-gray-700">
                            Gérez vos tâches de mesure et suivez leur progression.
                        </p>
                    </div>
                    <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
                        <Link
                            href="/tasks/create"
                            className="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700"
                        >
                            Nouvelle tâche
                        </Link>
                    </div>
                </div>

                {/* Statistiques */}
                {stats && (
                    <div className="mt-8">
                        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
                            <div className="bg-white overflow-hidden shadow rounded-lg">
                                <div className="p-5">
                                    <div className="flex items-center">
                                        <div className="flex-shrink-0">
                                            <div className="w-8 h-8 bg-indigo-500 rounded-md flex items-center justify-center">
                                                <span className="text-white text-sm font-medium">T</span>
                                            </div>
                                        </div>
                                        <div className="ml-5 w-0 flex-1">
                                            <dl>
                                                <dt className="text-sm font-medium text-gray-500 truncate">
                                                    Total tâches
                                                </dt>
                                                <dd className="text-lg font-medium text-gray-900">
                                                    {stats.total_tasks || 0}
                                                </dd>
                                            </dl>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="bg-white overflow-hidden shadow rounded-lg">
                                <div className="p-5">
                                    <div className="flex items-center">
                                        <div className="flex-shrink-0">
                                            <div className="w-8 h-8 bg-yellow-500 rounded-md flex items-center justify-center">
                                                <span className="text-white text-sm font-medium">A</span>
                                            </div>
                                        </div>
                                        <div className="ml-5 w-0 flex-1">
                                            <dl>
                                                <dt className="text-sm font-medium text-gray-500 truncate">
                                                    En attente
                                                </dt>
                                                <dd className="text-lg font-medium text-gray-900">
                                                    {stats.pending_tasks || 0}
                                                </dd>
                                            </dl>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="bg-white overflow-hidden shadow rounded-lg">
                                <div className="p-5">
                                    <div className="flex items-center">
                                        <div className="flex-shrink-0">
                                            <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                                                <span className="text-white text-sm font-medium">E</span>
                                            </div>
                                        </div>
                                        <div className="ml-5 w-0 flex-1">
                                            <dl>
                                                <dt className="text-sm font-medium text-gray-500 truncate">
                                                    En exécution
                                                </dt>
                                                <dd className="text-lg font-medium text-gray-900">
                                                    {stats.active_tasks || 0}
                                                </dd>
                                            </dl>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="bg-white overflow-hidden shadow rounded-lg">
                                <div className="p-5">
                                    <div className="flex items-center">
                                        <div className="flex-shrink-0">
                                            <div className="w-8 h-8 bg-gray-500 rounded-md flex items-center justify-center">
                                                <span className="text-white text-sm font-medium">C</span>
                                            </div>
                                        </div>
                                        <div className="ml-5 w-0 flex-1">
                                            <dl>
                                                <dt className="text-sm font-medium text-gray-500 truncate">
                                                    Clôturées
                                                </dt>
                                                <dd className="text-lg font-medium text-gray-900">
                                                    {stats.completed_tasks || 0}
                                                </dd>
                                            </dl>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {/* Liste des tâches */}
                <div className="mt-8">
                    <h2 className="text-lg font-medium text-gray-900 mb-4">Tâches récentes</h2>
                    <TaskList tasks={tasks} />
                </div>
            </div>
        </AppLayout>
    );
}