"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const mock_run_1 = __importDefault(require("azure-pipelines-task-lib/mock-run"));
const path_1 = __importDefault(require("path"));
let taskPath = path_1.default.join(__dirname, '..', 'index.js');
let taskRunner = new mock_run_1.default.TaskMockRunner(taskPath);
taskRunner.setInput('samplestring', 'bad');
taskRunner.run();
