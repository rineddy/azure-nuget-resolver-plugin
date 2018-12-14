import Task from 'azure-pipelines-task-lib/task';

async function run(): Promise<void> {
    try {
        const searchProjectFile: string = Task.getInput('searchProjectFile', true);
        if (searchProjectFile === 'bad') {
            Task.setResult(Task.TaskResult.Failed, 'Bad input was given');
            return;
        }
        console.log('Hello', searchProjectFile);
    }
    catch (err) {
        Task.setResult(Task.TaskResult.Failed, err.message);
    }
}

run();