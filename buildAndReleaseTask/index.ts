import Task from 'azure-pipelines-task-lib/task';

async function run(): Promise<void> {
    try {
        const inputString: string = Task.getInput('samplestring', true);
        if (inputString === 'bad') {
            Task.setResult(Task.TaskResult.Failed, 'Bad input was given');
            return;
        }
        console.log('Hello', inputString);
        Task.
    }
    catch (err) {
        Task.setResult(Task.TaskResult.Failed, err.message);
    }
}

run();