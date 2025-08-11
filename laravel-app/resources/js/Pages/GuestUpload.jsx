import { useState } from 'react';
import { Head, useForm } from '@inertiajs/react';

export default function GuestUpload({ task, token }) {
    const [previews, setPreviews] = useState([]);
    const { data, setData, post, processing, errors, progress } = useForm({
        photos: []
    });

    const handleFileChange = (e) => {
        const files = Array.from(e.target.files);
        setData('photos', files);

        // Créer les aperçus
        const newPreviews = files.map(file => ({
            file,
            url: URL.createObjectURL(file)
        }));
        setPreviews(newPreviews);
    };

    const removeFile = (index) => {
        const newFiles = data.photos.filter((_, i) => i !== index);
        const newPreviews = previews.filter((_, i) => i !== index);
        
        // Nettoyer l'URL de l'aperçu
        URL.revokeObjectURL(previews[index].url);
        
        setData('photos', newFiles);
        setPreviews(newPreviews);
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        post(`/guest/${token}/photos`);
    };

    return (
        <div className="min-h-screen bg-gray-50">
            <Head title={`Upload - ${task.title}`} />
            
            <div className="max-w-3xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
                {/* En-tête */}
                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold text-gray-900">Menui Measure</h1>
                    <p className="mt-2 text-lg text-gray-600">
                        Envoi de photos pour la tâche: <strong>{task.title}</strong>
                    </p>
                </div>

                {/* Instructions */}
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-8">
                    <h2 className="text-lg font-semibold text-blue-900 mb-4">
                        📏 Instructions importantes
                    </h2>
                    <ul className="space-y-2 text-sm text-blue-800">
                        <li className="flex items-start">
                            <span className="font-medium mr-2">1.</span>
                            Placez une feuille A4 (210×297 mm) sur le même plan que la surface à mesurer
                        </li>
                        <li className="flex items-start">
                            <span className="font-medium mr-2">2.</span>
                            Prenez la photo avec un angle inférieur à 15° si possible
                        </li>
                        <li className="flex items-start">
                            <span className="font-medium mr-2">3.</span>
                            Assurez-vous que l'éclairage est bon et évitez les ombres importantes
                        </li>
                        <li className="flex items-start">
                            <span className="font-medium mr-2">4.</span>
                            La feuille A4 doit être entièrement visible dans l'image
                        </li>
                    </ul>
                </div>

                {/* Formulaire d'upload */}
                <div className="bg-white shadow rounded-lg p-6">
                    <form onSubmit={handleSubmit} className="space-y-6">
                        {/* Zone de drop */}
                        <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-gray-400 transition-colors">
                            <input
                                type="file"
                                multiple
                                accept="image/jpeg,image/jpg,image/png"
                                onChange={handleFileChange}
                                className="hidden"
                                id="photo-upload"
                            />
                            <label htmlFor="photo-upload" className="cursor-pointer">
                                <div className="space-y-2">
                                    <svg className="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                                        <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                                    </svg>
                                    <div className="text-gray-600">
                                        <span className="font-medium text-indigo-600 hover:text-indigo-500">
                                            Cliquez pour sélectionner
                                        </span> ou glissez-déposez vos photos
                                    </div>
                                    <p className="text-xs text-gray-500">
                                        PNG, JPG jusqu'à 10MB par fichier
                                    </p>
                                </div>
                            </label>
                        </div>

                        {errors.photos && (
                            <div className="text-red-600 text-sm">{errors.photos}</div>
                        )}

                        {/* Aperçus des fichiers */}
                        {previews.length > 0 && (
                            <div className="space-y-4">
                                <h3 className="text-lg font-medium text-gray-900">
                                    Photos sélectionnées ({previews.length})
                                </h3>
                                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
                                    {previews.map((preview, index) => (
                                        <div key={index} className="relative group">
                                            <img
                                                src={preview.url}
                                                alt={`Aperçu ${index + 1}`}
                                                className="h-24 w-full object-cover rounded-lg"
                                            />
                                            <button
                                                type="button"
                                                onClick={() => removeFile(index)}
                                                className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity"
                                            >
                                                ×
                                            </button>
                                            <div className="mt-1 text-xs text-gray-500 truncate">
                                                {preview.file.name}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        {/* Bouton d'envoi */}
                        <div className="flex justify-end">
                            <button
                                type="submit"
                                disabled={processing || data.photos.length === 0}
                                className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                {processing ? 'Envoi en cours...' : `Envoyer ${data.photos.length} photo${data.photos.length > 1 ? 's' : ''}`}
                            </button>
                        </div>

                        {/* Barre de progression */}
                        {progress && (
                            <div className="w-full bg-gray-200 rounded-full h-2">
                                <div 
                                    className="bg-indigo-600 h-2 rounded-full transition-all duration-300"
                                    style={{ width: `${progress.percentage}%` }}
                                ></div>
                            </div>
                        )}
                    </form>
                </div>

                {/* Pied de page */}
                <div className="mt-8 text-center text-sm text-gray-500">
                    <p>Une fois vos photos envoyées, vous recevrez une confirmation.</p>
                    <p>L'équipe Menui Measure traitera vos mesures dans les plus brefs délais.</p>
                </div>
            </div>
        </div>
    );
}