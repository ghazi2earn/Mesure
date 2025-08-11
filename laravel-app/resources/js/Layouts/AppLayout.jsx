import { Head, Link, usePage } from '@inertiajs/react';

export default function AppLayout({ children, title }) {
    const { auth } = usePage().props;

    return (
        <div className="min-h-screen bg-gray-50">
            <Head title={title} />
            
            {/* Navigation */}
            <nav className="bg-white shadow-sm border-b border-gray-200">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between h-16">
                        <div className="flex items-center">
                            <Link href="/" className="flex-shrink-0">
                                <h1 className="text-xl font-bold text-indigo-600">Menui Measure</h1>
                            </Link>
                            
                            {auth?.user && (
                                <div className="hidden md:ml-6 md:flex md:space-x-8">
                                    <Link 
                                        href="/" 
                                        className="text-gray-900 hover:text-indigo-600 px-3 py-2 text-sm font-medium"
                                    >
                                        Tableau de bord
                                    </Link>
                                    <Link 
                                        href="/tasks" 
                                        className="text-gray-500 hover:text-indigo-600 px-3 py-2 text-sm font-medium"
                                    >
                                        Tâches
                                    </Link>
                                </div>
                            )}
                        </div>

                        {auth?.user && (
                            <div className="flex items-center space-x-4">
                                <span className="text-sm text-gray-700">
                                    Bonjour, {auth.user.name}
                                </span>
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                                    {auth.user.role}
                                </span>
                                <Link 
                                    href="/logout" 
                                    method="post"
                                    className="text-gray-500 hover:text-gray-700 px-3 py-2 text-sm font-medium"
                                >
                                    Déconnexion
                                </Link>
                            </div>
                        )}
                    </div>
                </div>
            </nav>

            {/* Contenu principal */}
            <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
                {children}
            </main>
        </div>
    );
}