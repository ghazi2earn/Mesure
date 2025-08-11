import AppLayout from '../Layouts/AppLayout';

export default function Test() {
    return (
        <AppLayout title="Test">
            <div className="px-4 sm:px-6 lg:px-8">
                <div className="bg-white shadow rounded-lg p-6">
                    <h1 className="text-2xl font-bold text-gray-900 mb-4">
                        🎉 Test de l'application Menui Measure
                    </h1>
                    
                    <div className="space-y-4">
                        <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                            <h2 className="text-lg font-semibold text-green-900">✅ React + Inertia.js</h2>
                            <p className="text-green-700">L'application React fonctionne correctement avec Inertia.js</p>
                        </div>
                        
                        <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                            <h2 className="text-lg font-semibold text-blue-900">🎨 Tailwind CSS</h2>
                            <p className="text-blue-700">Les styles Tailwind sont chargés et fonctionnels</p>
                        </div>
                        
                        <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
                            <h2 className="text-lg font-semibold text-purple-900">🏗️ Architecture</h2>
                            <p className="text-purple-700">
                                L'application est prête pour le développement avec Laravel 12 + React 18
                            </p>
                        </div>

                        <div className="mt-8">
                            <h3 className="text-lg font-semibold text-gray-900 mb-4">Prochaines étapes :</h3>
                            <ol className="list-decimal list-inside space-y-2 text-gray-700">
                                <li>Lancer <code className="bg-gray-100 px-2 py-1 rounded">docker-compose up --build</code></li>
                                <li>Exécuter les migrations</li>
                                <li>Créer un utilisateur admin</li>
                                <li>Tester l'upload d'images</li>
                            </ol>
                        </div>
                    </div>
                </div>
            </div>
        </AppLayout>
    );
}