import { Head } from '@inertiajs/react';
import { useState } from 'react';
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import ImageAnnotator from '@/Components/ImageAnnotator';

export default function TasksShow({ task }) {
    const [selectedPhoto, setSelectedPhoto] = useState(null);
    const [showAnnotator, setShowAnnotator] = useState(false);
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

    const openAnnotator = (photo) => {
        setSelectedPhoto(photo);
        setShowAnnotator(true);
    };

    const closeAnnotator = () => {
        setSelectedPhoto(null);
        setShowAnnotator(false);
    };

    const saveMeasurement = async (measurementData) => {
        try {
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
            
            const response = await fetch(`/tasks/${task.id}/measurements`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                },
                body: JSON.stringify({
                    photo_id: selectedPhoto.id,
                    type: measurementData.type,
                    points: measurementData.points,
                    value_mm: measurementData.distance_mm,
                    value_mm2: measurementData.area_mm2,
                    value_m2: measurementData.area_m2,
                    confidence: 1.0, // Mesure manuelle = confiance maximale
                    processor_version: 'manual-1.0.0'
                })
            });

            if (response.ok) {
                alert('Mesure sauvegardée avec succès !');
                // Optionnel: recharger la page pour voir la nouvelle mesure
                window.location.reload();
            } else {
                alert('Erreur lors de la sauvegarde de la mesure');
            }
        } catch (error) {
            console.error('Erreur:', error);
            alert('Erreur lors de la sauvegarde de la mesure');
        }
    };

    const generateGuestLink = async () => {
        try {
            // Récupérer le token CSRF de manière sécurisée
            const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
            
            if (!csrfToken) {
                alert('Erreur: Token CSRF non trouvé. Veuillez recharger la page.');
                return;
            }

            const response = await fetch(`/tasks/${task.id}/guest-link`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                },
            });
            
            if (response.ok) {
                const data = await response.json();
                // Copier le lien dans le presse-papiers
                try {
                    await navigator.clipboard.writeText(data.url);
                    alert('Lien copié dans le presse-papiers !');
                } catch (clipboardError) {
                    // Fallback si le presse-papiers n'est pas disponible
                    const textArea = document.createElement('textarea');
                    textArea.value = data.url;
                    document.body.appendChild(textArea);
                    textArea.select();
                    document.execCommand('copy');
                    document.body.removeChild(textArea);
                    alert('Lien copié dans le presse-papiers !');
                }
            } else {
                const errorData = await response.json().catch(() => ({}));
                alert(`Erreur lors de la génération du lien: ${errorData.message || 'Erreur inconnue'}`);
            }
        } catch (error) {
            console.error('Erreur lors de la génération du lien:', error);
            alert('Erreur lors de la génération du lien. Veuillez réessayer.');
        }
    };

    return (
        <AuthenticatedLayout
            header={
                <div className="flex justify-between items-center">
                    <div className="flex items-center gap-4">
                        <a
                            href="/tasks"
                            className="text-gray-600 hover:text-gray-800 text-sm font-medium"
                        >
                            ← Retour aux tâches
                        </a>
                        <h2 className="font-semibold text-xl text-gray-800 leading-tight">
                            {task.title}
                        </h2>
                        {getStatusBadge(task.status)}
                    </div>
                    <div className="flex gap-2">
                        <button
                            onClick={generateGuestLink}
                            className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                        >
                            Générer un lien
                        </button>
                        <a
                            href={`/tasks/${task.id}/edit`}
                            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                        >
                            Modifier
                        </a>
                    </div>
                </div>
            }
        >
            <Head title={task.title} />

            <div className="py-12">
                <div className="max-w-7xl mx-auto sm:px-6 lg:px-8">
                    <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div className="p-6">
                            {/* Informations de la tâche */}
                            <div className="mb-8">
                                <h3 className="text-lg font-medium text-gray-900 mb-4">Informations</h3>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700">Description</label>
                                        <p className="mt-1 text-sm text-gray-900">
                                            {task.description || 'Aucune description'}
                                        </p>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700">Créée le</label>
                                        <p className="mt-1 text-sm text-gray-900">
                                            {new Date(task.created_at).toLocaleDateString('fr-FR')}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            {/* Photos */}
                            <div className="mb-8">
                                <div className="flex justify-between items-center mb-4">
                                    <h3 className="text-lg font-medium text-gray-900">
                                        Photos ({task.photos?.length || 0})
                                    </h3>
                                </div>
                                
                                {task.photos && task.photos.length > 0 ? (
                                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                        {task.photos.map((photo) => (
                                            <div key={photo.id} className="border border-gray-200 rounded-lg p-4">
                                                <div className="aspect-w-16 aspect-h-9 mb-3">
                                                    <img
                                                        src={`/storage/${photo.path}`}
                                                        alt="Photo"
                                                        className="w-full h-48 object-cover rounded cursor-pointer hover:opacity-80 transition"
                                                        onClick={() => openAnnotator(photo)}
                                                    />
                                                </div>
                                                <div className="text-sm text-gray-600 mb-3">
                                                    <p>Statut: {photo.processed ? 'Traité' : 'En cours'}</p>
                                                    {photo.metadata?.pixels_per_mm && (
                                                        <p>Précision: {photo.metadata.pixels_per_mm.toFixed(2)} px/mm</p>
                                                    )}
                                                </div>
                                                {photo.processed && photo.metadata?.pixels_per_mm && (
                                                    <button
                                                        onClick={() => openAnnotator(photo)}
                                                        className="w-full bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded text-sm font-medium transition"
                                                    >
                                                        📏 Mesurer
                                                    </button>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="text-center py-8 text-gray-500">
                                        <svg className="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                        </svg>
                                        <p>Aucune photo uploadée</p>
                                        <p className="text-sm">Utilisez le lien d'invitation pour permettre l'upload de photos</p>
                                    </div>
                                )}
                            </div>

                            {/* Mesures */}
                            {task.measurements && task.measurements.length > 0 && (
                                <div className="mb-8">
                                    <h3 className="text-lg font-medium text-gray-900 mb-4">
                                        Mesures ({task.measurements.length})
                                    </h3>
                                    <div className="space-y-4">
                                        {task.measurements.map((measurement) => (
                                            <div key={measurement.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                                                <div className="flex justify-between items-start mb-3">
                                                    <div className="flex items-center space-x-3">
                                                        <div className={`w-3 h-3 rounded-full ${measurement.type === 'length' ? 'bg-red-500' : 'bg-blue-500'}`}></div>
                                                        <div>
                                                            <p className="font-semibold text-gray-900">
                                                                {measurement.type === 'length' ? '📏 Distance' : '⬜ Surface'}
                                                            </p>
                                                            <p className="text-xs text-gray-500">
                                                                ID: {measurement.id} • {measurement.processor_version}
                                                            </p>
                                                        </div>
                                                    </div>
                                                    <div className="text-right">
                                                        <div className="text-sm text-gray-500">
                                                            {new Date(measurement.created_at).toLocaleDateString('fr-FR', {
                                                                day: '2-digit',
                                                                month: '2-digit', 
                                                                year: 'numeric',
                                                                hour: '2-digit',
                                                                minute: '2-digit'
                                                            })}
                                                        </div>
                                                        <div className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                                                            measurement.confidence >= 0.9 ? 'bg-green-100 text-green-800' :
                                                            measurement.confidence >= 0.7 ? 'bg-yellow-100 text-yellow-800' :
                                                            'bg-red-100 text-red-800'
                                                        }`}>
                                                            {Math.round(measurement.confidence * 100)}% confiance
                                                        </div>
                                                    </div>
                                                </div>
                                                
                                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                    <div className="bg-gray-50 rounded-lg p-3">
                                                        <h4 className="font-medium text-gray-900 mb-2">Valeurs mesurées</h4>
                                                        {measurement.type === 'length' ? (
                                                            <div className="space-y-1">
                                                                <div className="flex justify-between">
                                                                    <span className="text-sm text-gray-600">Millimètres:</span>
                                                                    <span className="font-mono text-sm">{measurement.value_mm?.toFixed(2)} mm</span>
                                                                </div>
                                                                <div className="flex justify-between">
                                                                    <span className="text-sm text-gray-600">Mètres:</span>
                                                                    <span className="font-mono text-sm font-semibold text-blue-600">
                                                                        {(measurement.value_mm / 1000)?.toFixed(3)} m
                                                                    </span>
                                                                </div>
                                                            </div>
                                                        ) : (
                                                            <div className="space-y-1">
                                                                <div className="flex justify-between">
                                                                    <span className="text-sm text-gray-600">mm²:</span>
                                                                    <span className="font-mono text-sm">{measurement.value_mm2?.toFixed(0)} mm²</span>
                                                                </div>
                                                                <div className="flex justify-between">
                                                                    <span className="text-sm text-gray-600">m²:</span>
                                                                    <span className="font-mono text-sm font-semibold text-blue-600">
                                                                        {measurement.value_m2?.toFixed(6)} m²
                                                                    </span>
                                                                </div>
                                                                <div className="flex justify-between">
                                                                    <span className="text-sm text-gray-600">cm²:</span>
                                                                    <span className="font-mono text-sm">{(measurement.value_mm2 / 100)?.toFixed(2)} cm²</span>
                                                                </div>
                                                            </div>
                                                        )}
                                                    </div>
                                                    
                                                    <div className="bg-gray-50 rounded-lg p-3">
                                                        <h4 className="font-medium text-gray-900 mb-2">Informations techniques</h4>
                                                        <div className="space-y-1">
                                                            <div className="flex justify-between">
                                                                <span className="text-sm text-gray-600">Photo:</span>
                                                                <span className="text-sm">#{measurement.photo_id}</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-sm text-gray-600">Points:</span>
                                                                <span className="text-sm">{measurement.points?.length || 0} point(s)</span>
                                                            </div>
                                                            <div className="flex justify-between">
                                                                <span className="text-sm text-gray-600">Type:</span>
                                                                <span className={`text-sm px-2 py-1 rounded ${
                                                                    measurement.processor_version?.includes('manual') 
                                                                        ? 'bg-purple-100 text-purple-800' 
                                                                        : 'bg-green-100 text-green-800'
                                                                }`}>
                                                                    {measurement.processor_version?.includes('manual') ? 'Manuel' : 'Automatique'}
                                                                </span>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                                
                                                {measurement.points && measurement.points.length > 0 && (
                                                    <div className="mt-3 pt-3 border-t border-gray-200">
                                                        <button 
                                                            onClick={() => openAnnotator(task.photos.find(p => p.id === measurement.photo_id))}
                                                            className="text-sm text-blue-600 hover:text-blue-800 font-medium"
                                                        >
                                                            🔍 Voir sur la photo
                                                        </button>
                                                    </div>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Modal de mesure */}
            {showAnnotator && selectedPhoto && (
                <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-lg max-w-6xl max-h-[90vh] w-full overflow-hidden">
                        <div className="flex justify-between items-center p-4 border-b">
                            <h3 className="text-lg font-medium">
                                Mesurer sur la photo: {selectedPhoto.filename}
                            </h3>
                            <button
                                onClick={closeAnnotator}
                                className="text-gray-400 hover:text-gray-600 text-2xl font-bold"
                            >
                                ×
                            </button>
                        </div>
                        <div className="p-4 overflow-auto max-h-[calc(90vh-120px)]">
                            <ImageAnnotator
                                imageUrl={`/storage/${selectedPhoto.path}`}
                                onSave={saveMeasurement}
                                suggestions={selectedPhoto.measurements?.map(m => ({
                                    mask_poly: m.points,
                                    type: m.type,
                                    confidence: m.confidence
                                })) || []}
                                pixelsPerMm={selectedPhoto.metadata?.pixels_per_mm}
                            />
                        </div>
                    </div>
                </div>
            )}
        </AuthenticatedLayout>
    );
}
