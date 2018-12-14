import Task from 'azure-pipelines-task-lib/task';

async function run(): Promise<void> {
    try {
        const searchProjectFile: string = Task.getInput('searchProjectFile', true);
        if (!searchProjectFile.match(/\.csproj$/i)) {
            Task.setResult(Task.TaskResult.Failed, 'Search project file: invalid input');
            return;
        }
        console.log('Searching: ', searchProjectFile);
    }
    catch (err) {
        Task.setResult(Task.TaskResult.Failed, err.message);
    }
}

run();