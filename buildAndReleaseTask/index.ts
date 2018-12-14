import Task from 'azure-pipelines-task-lib/task';

async function run(): Promise<void> {
    try {
        const searchProjectFile: string = Task.getInput('searchProjectFile', true);
        if (!searchProjectFile.match(/\.csproj$/i)) {
            Task.setResult(Task.TaskResult.Failed, 'Search project file: invalid input');
            return;
        }
        console.log('Searching: ', searchProjectFile);
        console.log('Working directory: ', __dirname);

        let files = Task.find(__dirname + '/' + searchProjectFile);
        files.forEach(file => {
            console.log(file);
        });
    }
    catch (err) {
        Task.setResult(Task.TaskResult.Failed, err.message);
    }
}

run();