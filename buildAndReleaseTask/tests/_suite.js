"use strict";
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const Path = __importStar(require("path"));
const Assert = __importStar(require("assert"));
const MockTest = __importStar(require("azure-pipelines-task-lib/mock-test"));
describe('Testing the TFS extension...', function () {
    before(() => {
        // ACTIONS TO DO BEFORE EACH TEST
    });
    after(() => {
        // ACTIONS TO DO AFTER EACH TEST
    });
    it('should succeed with simple inputs', (done) => {
        this.timeout(1000);
        let testPath = Path.join(__dirname, 'success.js');
        let testRunner = new MockTest.MockTestRunner(testPath);
        testRunner.run();
        console.log(testRunner.succeeded);
        Assert.equal(testRunner.succeeded, true, 'should have succeeded');
        Assert.equal(testRunner.warningIssues.length, 0, 'should have no warnings');
        Assert.equal(testRunner.errorIssues.length, 0, 'should have no errors');
        console.log(testRunner.stdout);
        Assert.equal(testRunner.stdout.indexOf('Hello human') >= 0, true, 'should display Hello human');
        done();
    });
    it('it should fail if tool returns 1', (done) => {
        this.timeout(1000);
        let testPath = Path.join(__dirname, 'failure.js');
        let testRunner = new MockTest.MockTestRunner(testPath);
        testRunner.run();
        console.log(testRunner.succeeded);
        Assert.equal(testRunner.succeeded, false, 'should have failed');
        Assert.equal(testRunner.warningIssues, 0, 'should have no warnings');
        Assert.equal(testRunner.errorIssues.length, 1, 'should have 1 error issue');
        Assert.equal(testRunner.errorIssues[0], 'Bad input was given', 'error issue output');
        Assert.equal(testRunner.stdout.indexOf('Hello bad'), -1, 'Should not display Hello bad');
        done();
    });
});
