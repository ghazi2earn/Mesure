import React, { useState, useCallback } from 'react';
import { useForm } from '@inertiajs/react';
import { Upload, X, CheckCircle, AlertCircle, Camera } from 'lucide-react';

export default function GuestUpload({ task, token }) {
    const [previews, setPreviews] = useState([]);
    const [uploading, setUploading] = useState(false);
    const [uploadSuccess, setUploadSuccess] = useState(false);
    const [error, setError] = useState(null);

    const { data, setData, post, processing, errors } = useForm({
        photos: [],
        contact_email: '',
        contact_phone: '',
    });

    const handleFileSelect = useCallback((e) => {
        const files = Array.from(e.target.files);
        const validFiles = files.filter(file => {
            const isValid = file.type.startsWith('image/') && file.size <= 10 * 1024 * 1024;
            if (!isValid && file.size > 10 * 1024 * 1024) {
                setError('Certains fichiers dépassent la taille maximale de 10 MB');
            }
            return isValid;
        });

        if (data.photos.length + validFiles.length > 10) {
            setError('Vous pouvez télécharger maximum 10 photos');
            return;
        }

        const newPhotos = [...data.photos, ...validFiles];
        setData('photos', newPhotos);

        // Créer les aperçus
        validFiles.forEach(file => {
            const reader = new FileReader();
            reader.onloadend = () => {
                setPreviews(prev => [...prev, {
                    file: file,
                    url: reader.result,
                    name: file.name,
                }]);
            };
            reader.readAsDataURL(file);
        });

        setError(null);
    }, [data.photos]);

    const removePhoto = useCallback((index) => {
        const newPhotos = data.photos.filter((_, i) => i !== index);
        setData('photos', newPhotos);
        setPreviews(prev => prev.filter((_, i) => i !== index));
    }, [data.photos]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (data.photos.length === 0) {
            setError('Veuillez sélectionner au moins une photo');
            return;
        }

        setUploading(true);
        setError(null);

        const formData = new FormData();
        data.photos.forEach(photo => {
            formData.append('photos[]', photo);
        });
        if (data.contact_email) formData.append('contact_email', data.contact_email);
        if (data.contact_phone) formData.append('contact_phone', data.contact_phone);

        try {
            const response = await fetch(`/guest/${token}/photos`, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content,
                },
            });

            const result = await response.json();

            if (response.ok) {
                setUploadSuccess(true);
                setData({
                    photos: [],
                    contact_email: '',
                    contact_phone: '',
                });
                setPreviews([]);
            } else {
                setError(result.message || 'Une erreur est survenue');
            }
        } catch (err) {
            setError('Erreur de connexion. Veuillez réessayer.');
        } finally {
            setUploading(false);
        }
    };

    if (uploadSuccess) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
                <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8 text-center">
                    <CheckCircle className="w-16 h-16 text-green-500 mx-auto mb-4" />
                    <h2 className="text-2xl font-bold text-gray-900 mb-2">
                        Photos envoyées avec succès !
                    </h2>
                    <p className="text-gray-600 mb-6">
                        Vos photos ont été téléchargées et sont en cours de traitement. 
                        Nous vous contacterons une fois l'analyse terminée.
                    </p>
                    <button
                        onClick={() => window.location.reload()}
                        className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition"
                    >
                        Envoyer d'autres photos
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-4xl mx-auto px-4">
                {/* En-tête */}
                <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
                    <h1 className="text-2xl font-bold text-gray-900 mb-2">
                        {task.title}
                    </h1>
                    {task.description && (
                        <p className="text-gray-600 mb-4">{task.description}</p>
                    )}
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                        <h3 className="font-semibold text-blue-900 mb-2">
                            📸 Instructions pour les photos
                        </h3>
                        <ul className="text-sm text-blue-800 space-y-1">
                            <li>• Placez une feuille A4 sur la même surface que l'objet à mesurer</li>
                            <li>• La feuille A4 doit être complètement visible et plate</li>
                            <li>• Prenez la photo de face autant que possible (angle &lt; 15°)</li>
                            <li>• Assurez-vous d'un bon éclairage sans reflets</li>
                            <li>• Maximum 10 photos, 10 MB par photo</li>
                        </ul>
                    </div>
                </div>

                {/* Zone de téléchargement */}
                <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-lg p-6">
                    <div className="mb-6">
                        <label className="block text-gray-700 font-semibold mb-4">
                            Télécharger vos photos
                        </label>
                        
                        {/* Zone de dépôt */}
                        <div className="relative">
                            <input
                                type="file"
                                multiple
                                accept="image/*"
                                onChange={handleFileSelect}
                                className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                                disabled={uploading}
                            />
                            <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-blue-400 transition">
                                <Upload className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                                <p className="text-gray-600">
                                    Cliquez ou glissez vos photos ici
                                </p>
                                <p className="text-sm text-gray-500 mt-1">
                                    JPG, PNG jusqu'à 10 MB
                                </p>
                            </div>
                        </div>

                        {/* Aperçus */}
                        {previews.length > 0 && (
                            <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-6">
                                {previews.map((preview, index) => (
                                    <div key={index} className="relative group">
                                        <img
                                            src={preview.url}
                                            alt={preview.name}
                                            className="w-full h-32 object-cover rounded-lg"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => removePhoto(index)}
                                            className="absolute top-2 right-2 bg-red-500 text-white p-1 rounded-full opacity-0 group-hover:opacity-100 transition"
                                            disabled={uploading}
                                        >
                                            <X className="w-4 h-4" />
                                        </button>
                                        <p className="text-xs text-gray-600 mt-1 truncate">
                                            {preview.name}
                                        </p>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Informations de contact (optionnel) */}
                    <div className="border-t pt-6">
                        <h3 className="font-semibold text-gray-700 mb-4">
                            Informations de contact (optionnel)
                        </h3>
                        <div className="grid md:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    Email
                                </label>
                                <input
                                    type="email"
                                    value={data.contact_email}
                                    onChange={e => setData('contact_email', e.target.value)}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                                    placeholder="votre@email.com"
                                    disabled={uploading}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">
                                    Téléphone
                                </label>
                                <input
                                    type="tel"
                                    value={data.contact_phone}
                                    onChange={e => setData('contact_phone', e.target.value)}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                                    placeholder="06 12 34 56 78"
                                    disabled={uploading}
                                />
                            </div>
                        </div>
                    </div>

                    {/* Erreurs */}
                    {error && (
                        <div className="mt-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-start">
                            <AlertCircle className="w-5 h-5 text-red-500 mr-2 flex-shrink-0 mt-0.5" />
                            <p className="text-red-700 text-sm">{error}</p>
                        </div>
                    )}

                    {/* Bouton de soumission */}
                    <div className="mt-6">
                        <button
                            type="submit"
                            disabled={uploading || data.photos.length === 0}
                            className={`w-full py-3 px-4 rounded-lg font-medium transition ${
                                uploading || data.photos.length === 0
                                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                                    : 'bg-blue-600 text-white hover:bg-blue-700'
                            }`}
                        >
                            {uploading ? (
                                <span className="flex items-center justify-center">
                                    <svg className="animate-spin h-5 w-5 mr-3" viewBox="0 0 24 24">
                                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                                    </svg>
                                    Envoi en cours...
                                </span>
                            ) : (
                                `Envoyer ${data.photos.length > 0 ? `${data.photos.length} photo${data.photos.length > 1 ? 's' : ''}` : 'les photos'}`
                            )}
                        </button>
                    </div>
                </form>

                {/* Informations existantes */}
                {task.existing_photos_count > 0 && (
                    <div className="mt-4 text-center text-sm text-gray-600">
                        {task.existing_photos_count} photo{task.existing_photos_count > 1 ? 's' : ''} déjà téléchargée{task.existing_photos_count > 1 ? 's' : ''}
                    </div>
                )}
            </div>
        </div>
    );
}