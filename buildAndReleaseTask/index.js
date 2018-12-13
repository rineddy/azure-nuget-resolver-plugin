"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const task_1 = __importDefault(require("azure-pipelines-task-lib/task"));
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const inputString = task_1.default.getInput('samplestring', true);
            if (inputString === 'bad') {
                task_1.default.setResult(task_1.default.TaskResult.Failed, 'Bad input was given');
                return;
            }
            console.log('Hello', inputString);
        }
        catch (err) {
            task_1.default.setResult(task_1.default.TaskResult.Failed, err.message);
        }
    });
}
run();
