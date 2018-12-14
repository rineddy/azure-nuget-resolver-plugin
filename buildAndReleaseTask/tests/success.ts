import MockRun from 'azure-pipelines-task-lib/mock-run';
import Path from 'path';

let taskPath = Path.join(__dirname, '..', 'index.js');
let taskRunner: MockRun.TaskMockRunner = new MockRun.TaskMockRunner(taskPath);

import * as MockAnswer from 'azure-pipelines-task-lib/mock-answer';
taskRunner.setAnswers({
    findMatch: {
        '*.js': ['file.js']
    }
});

taskRunner.setInput('searchProjectFile', '*.csproj');
taskRunner.run();