import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import { Head, Link, router } from '@inertiajs/react';
import { useState, useEffect } from 'react';

function StatCard({ title, value, subtext, color = 'blue' }) {
    const colorClasses = {
        blue: 'bg-blue-500 text-white',
        green: 'bg-green-500 text-white',
        yellow: 'bg-yellow-500 text-white',
        red: 'bg-red-500 text-white',
        purple: 'bg-purple-500 text-white',
    };

    return (
        <div className={`p-6 rounded-lg shadow-sm ${colorClasses[color]}`}>
            <h3 className="text-lg font-semibold">{title}</h3>
            <p className="text-3xl font-bold mt-2">{value}</p>
            {subtext && <p className="text-sm opacity-90 mt-1">{subtext}</p>}
        </div>
    );
}

function NotificationItem({ notification }) {
    const getStatusColor = (status) => {
        return status === 'sent' ? 'text-green-600' : 'text-red-600';
    };

    const getTypeIcon = (type) => {
        switch (type) {
            case 'email': return '📧';
            case 'sms': return '📱';
            case 'whatsapp': return '📲';
            case 'push': return '🔔';
            default: return '📢';
        }
    };

    return (
        <div className="p-4 border-l-4 border-blue-500 bg-gray-50 rounded">
            <div className="flex items-start justify-between">
                <div className="flex-1">
                    <div className="flex items-center gap-2">
                        <span className="text-lg">{getTypeIcon(notification.type)}</span>
                        <h4 className="font-medium text-gray-900">
                            {notification.payload?.subject || 'Notification'}
                        </h4>
                        <span className={`text-xs px-2 py-1 rounded ${getStatusColor(notification.status)}`}>
                            {notification.status}
                        </span>
                    </div>
                    <p className="text-sm text-gray-600 mt-1">
                        {notification.payload?.message || 'Aucun message'}
                    </p>
                    <p className="text-xs text-gray-500 mt-2">
                        Tâche: {notification.task_title} • {new Date(notification.sent_at).toLocaleString('fr-FR')}
                    </p>
                </div>
            </div>
        </div>
    );
}

function RecentTaskItem({ task }) {
    const getStatusColor = (status) => {
        switch (status) {
            case 'nouveau': return 'bg-gray-100 text-gray-800';
            case 'en_attente': return 'bg-yellow-100 text-yellow-800';
            case 'en_execution': return 'bg-blue-100 text-blue-800';
            case 'cloture': return 'bg-green-100 text-green-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    const getStatusLabel = (status) => {
        switch (status) {
            case 'nouveau': return 'Nouveau';
            case 'en_attente': return 'En attente';
            case 'en_execution': return 'En cours';
            case 'cloture': return 'Clôturé';
            default: return status;
        }
    };

    return (
        <Link 
            href={route('tasks.show', task.id)}
            className="block p-4 border rounded-lg hover:shadow-md transition-shadow"
        >
            <div className="flex items-start justify-between">
                <div className="flex-1">
                    <h4 className="font-medium text-gray-900">{task.title}</h4>
                    <div className="flex items-center gap-4 mt-2 text-sm text-gray-600">
                        <span>📷 {task.photos_count} photos</span>
                        <span>✅ {task.processed_photos_count} traitées</span>
                    </div>
                    <p className="text-xs text-gray-500 mt-2">
                        {new Date(task.created_at).toLocaleDateString('fr-FR')}
                    </p>
                </div>
                <span className={`px-2 py-1 rounded text-xs ${getStatusColor(task.status)}`}>
                    {getStatusLabel(task.status)}
                </span>
            </div>
        </Link>
    );
}

function PhotoActivityItem({ photo }) {
    return (
        <div className="flex items-center gap-3 p-3 border rounded">
            <div className={`w-3 h-3 rounded-full ${photo.processed ? 'bg-green-500' : 'bg-yellow-500'}`}></div>
            <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">{photo.filename}</p>
                <p className="text-xs text-gray-600">
                    {photo.task_title} • {new Date(photo.created_at).toLocaleTimeString('fr-FR')}
                </p>
            </div>
            <div className="text-xs text-gray-500">
                {photo.processed ? '✅' : '⏳'} {photo.has_measurements ? '📏' : ''}
            </div>
        </div>
    );
}

export default function Dashboard({ stats, recentTasks, recentNotifications, todayPhotos }) {
    const [notifications, setNotifications] = useState(recentNotifications || []);
    const [lastUpdate, setLastUpdate] = useState(new Date().toISOString());

    // Fonction pour récupérer les nouvelles notifications
    const fetchNotifications = async () => {
        try {
            const response = await fetch(route('dashboard.notifications', { since: lastUpdate }));
            const data = await response.json();
            
            if (data.notifications && data.notifications.length > 0) {
                setNotifications(prev => [...data.notifications, ...prev].slice(0, 10));
            }
            setLastUpdate(data.timestamp);
        } catch (error) {
            console.error('Erreur lors de la récupération des notifications:', error);
        }
    };

    // Vérifier les nouvelles notifications toutes les 30 secondes
    useEffect(() => {
        const interval = setInterval(fetchNotifications, 30000);
        return () => clearInterval(interval);
    }, [lastUpdate]);

    return (
        <AuthenticatedLayout
            header={
                <div className="flex justify-between items-center">
                <h2 className="text-xl font-semibold leading-tight text-gray-800">
                        Tableau de bord
                </h2>
                    <Link
                        href={route('tasks.create')}
                        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                    >
                        Nouvelle tâche
                    </Link>
                </div>
            }
        >
            <Head title="Dashboard" />

            <div className="py-12">
                <div className="mx-auto max-w-7xl sm:px-6 lg:px-8 space-y-6">
                    
                    {/* Statistiques */}
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
                        <StatCard 
                            title="Total tâches" 
                            value={stats.total_tasks} 
                            color="blue"
                        />
                        <StatCard 
                            title="En attente" 
                            value={stats.pending_tasks} 
                            color="yellow"
                        />
                        <StatCard 
                            title="En cours" 
                            value={stats.in_progress_tasks} 
                            color="purple"
                        />
                        <StatCard 
                            title="Terminées" 
                            value={stats.completed_tasks} 
                            color="green"
                        />
                        <StatCard 
                            title="Photos traitées" 
                            value={`${stats.processed_photos}/${stats.total_photos}`}
                            subtext={stats.total_photos > 0 ? `${Math.round((stats.processed_photos / stats.total_photos) * 100)}%` : '0%'}
                            color="blue"
                        />
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                        
                        {/* Tâches récentes */}
                        <div className="bg-white shadow-sm rounded-lg overflow-hidden">
                            <div className="px-6 py-4 border-b border-gray-200">
                                <div className="flex justify-between items-center">
                                    <h3 className="text-lg font-medium text-gray-900">Tâches récentes</h3>
                                    <Link 
                                        href={route('tasks.index')}
                                        className="text-sm text-blue-600 hover:text-blue-800"
                                    >
                                        Voir tout
                                    </Link>
                                </div>
                            </div>
                            <div className="p-6 space-y-4">
                                {recentTasks.length > 0 ? (
                                    recentTasks.map(task => (
                                        <RecentTaskItem key={task.id} task={task} />
                                    ))
                                ) : (
                                    <p className="text-gray-500 text-center py-8">
                                        Aucune tâche récente
                                    </p>
                                )}
                            </div>
                        </div>

                        {/* Notifications */}
                        <div className="bg-white shadow-sm rounded-lg overflow-hidden">
                            <div className="px-6 py-4 border-b border-gray-200">
                                <h3 className="text-lg font-medium text-gray-900">
                                    Notifications récentes
                                    {notifications.length > 0 && (
                                        <span className="ml-2 bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                                            {notifications.length}
                                        </span>
                                    )}
                                </h3>
                            </div>
                            <div className="p-6 space-y-4 max-h-96 overflow-y-auto">
                                {notifications.length > 0 ? (
                                    notifications.map(notification => (
                                        <NotificationItem key={notification.id} notification={notification} />
                                    ))
                                ) : (
                                    <p className="text-gray-500 text-center py-8">
                                        Aucune notification
                                    </p>
                                )}
                            </div>
                        </div>

                        {/* Activité du jour */}
                        <div className="bg-white shadow-sm rounded-lg overflow-hidden">
                            <div className="px-6 py-4 border-b border-gray-200">
                                <h3 className="text-lg font-medium text-gray-900">
                                    Photos du jour
                                    {todayPhotos.length > 0 && (
                                        <span className="ml-2 bg-green-100 text-green-800 text-xs px-2 py-1 rounded-full">
                                            {todayPhotos.length}
                                        </span>
                                    )}
                                </h3>
                            </div>
                            <div className="p-6 space-y-3 max-h-96 overflow-y-auto">
                                {todayPhotos.length > 0 ? (
                                    todayPhotos.map(photo => (
                                        <PhotoActivityItem key={photo.id} photo={photo} />
                                    ))
                                ) : (
                                    <p className="text-gray-500 text-center py-8">
                                        Aucune photo uploadée aujourd'hui
                                    </p>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Actions rapides */}
                    <div className="bg-white shadow-sm rounded-lg p-6">
                        <h3 className="text-lg font-medium text-gray-900 mb-4">Actions rapides</h3>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <Link
                                href={route('tasks.create')}
                                className="flex items-center gap-3 p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors"
                            >
                                <span className="text-2xl">➕</span>
                                <div>
                                    <h4 className="font-medium text-gray-900">Nouvelle tâche</h4>
                                    <p className="text-sm text-gray-600">Créer une nouvelle tâche de mesure</p>
                                </div>
                            </Link>
                            
                            <Link
                                href={route('tasks.index')}
                                className="flex items-center gap-3 p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors"
                            >
                                <span className="text-2xl">📋</span>
                                <div>
                                    <h4 className="font-medium text-gray-900">Voir les tâches</h4>
                                    <p className="text-sm text-gray-600">Gérer toutes vos tâches</p>
                                </div>
                            </Link>

                            <button
                                onClick={() => window.location.reload()}
                                className="flex items-center gap-3 p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors"
                            >
                                <span className="text-2xl">🔄</span>
                                <div>
                                    <h4 className="font-medium text-gray-900">Actualiser</h4>
                                    <p className="text-sm text-gray-600">Mettre à jour les données</p>
                                </div>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </AuthenticatedLayout>
    );
}