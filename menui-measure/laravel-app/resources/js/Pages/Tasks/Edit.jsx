import { Head, useForm } from '@inertiajs/react';
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout';
import InputError from '@/Components/InputError';
import InputLabel from '@/Components/InputLabel';
import PrimaryButton from '@/Components/PrimaryButton';
import TextInput from '@/Components/TextInput';

export default function TasksEdit({ task }) {
    const { data, setData, put, processing, errors } = useForm({
        title: task.title,
        description: task.description || '',
        status: task.status,
    });

    const submit = (e) => {
        e.preventDefault();
        put(`/tasks/${task.id}`);
    };

    return (
        <AuthenticatedLayout
            header={
                <div className="flex justify-between items-center">
                    <div className="flex items-center gap-4">
                        <a
                            href={`/tasks/${task.id}`}
                            className="text-gray-600 hover:text-gray-800 text-sm font-medium"
                        >
                            ← Retour à la tâche
                        </a>
                        <h2 className="font-semibold text-xl text-gray-800 leading-tight">
                            Modifier la tâche
                        </h2>
                    </div>
                </div>
            }
        >
            <Head title={`Modifier - ${task.title}`} />

            <div className="py-12">
                <div className="max-w-2xl mx-auto sm:px-6 lg:px-8">
                    <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <div className="p-6">
                            <form onSubmit={submit}>
                                <div className="mb-6">
                                    <InputLabel htmlFor="title" value="Titre de la tâche" />
                                    <TextInput
                                        id="title"
                                        type="text"
                                        name="title"
                                        value={data.title}
                                        className="mt-1 block w-full"
                                        autoComplete="off"
                                        isFocused={true}
                                        onChange={(e) => setData('title', e.target.value)}
                                        required
                                    />
                                    <InputError message={errors.title} className="mt-2" />
                                </div>

                                <div className="mb-6">
                                    <InputLabel htmlFor="description" value="Description (optionnel)" />
                                    <textarea
                                        id="description"
                                        name="description"
                                        value={data.description}
                                        className="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm"
                                        rows={4}
                                        onChange={(e) => setData('description', e.target.value)}
                                    />
                                    <InputError message={errors.description} className="mt-2" />
                                </div>

                                <div className="mb-6">
                                    <InputLabel htmlFor="status" value="Statut" />
                                    <select
                                        id="status"
                                        name="status"
                                        value={data.status}
                                        className="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm"
                                        onChange={(e) => setData('status', e.target.value)}
                                    >
                                        <option value="nouveau">Nouveau</option>
                                        <option value="en_attente">En attente</option>
                                        <option value="en_execution">En exécution</option>
                                        <option value="cloture">Clôturé</option>
                                    </select>
                                    <InputError message={errors.status} className="mt-2" />
                                </div>

                                <div className="flex items-center justify-end gap-4">
                                    <a
                                        href={`/tasks/${task.id}`}
                                        className="text-gray-600 hover:text-gray-800 text-sm font-medium"
                                    >
                                        Annuler
                                    </a>
                                    <PrimaryButton disabled={processing}>
                                        {processing ? 'Mise à jour...' : 'Mettre à jour'}
                                    </PrimaryButton>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </AuthenticatedLayout>
    );
}
