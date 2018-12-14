import MockAnswer from 'azure-pipelines-task-lib/mock-answer';
import MockRun from 'azure-pipelines-task-lib/mock-run';
import Path from 'path';

let taskPath = Path.join(__dirname, '..', 'index.js');
let taskRunner: MockRun.TaskMockRunner = new MockRun.TaskMockRunner(taskPath);

taskRunner.setInput('searchProjectFile', '*.txt');
taskRunner.run();