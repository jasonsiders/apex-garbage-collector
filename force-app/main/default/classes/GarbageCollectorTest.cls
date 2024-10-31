@SuppressWarnings('PMD.ApexDoc, PMD.EmptyCatchBlock')
@IsTest
private class GarbageCollectorTest {
    // **** CONSTANTS **** //
    static final Integer TEST_SIZE = 10;

    // **** TESTS **** //
	@IsTest
	static void shouldDeleteRecords() {
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(TEST_SIZE, tasks?.size(), 'Wrong # of deleted Tasks');
		// Validate that the records were not hard deleted
		try {
			undelete tasks;
		} catch (System.DmlException error) {
			Assert.fail('Records may have been removed from recycle bin: ' + error);
		}
	}

	@IsTest
	static void shouldHardDeleteRecords() {
		GarbageCollector__mdt settings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		settings.HardDelete__c = true;

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(TEST_SIZE, tasks?.size(), 'Wrong # of deleted Tasks');
		// Validate that the records were hard-deleted
		try {
			undelete tasks;
			Assert.fail('Records were not removed from the recycle bin');
		} catch (System.DmlException error) {
			// As expected...
		}
	}

	@IsTest
	static void shouldUseApexBasedJob() {
		GarbageCollector__mdt settings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		settings.ApexClassName__c = TestLocator.class.getName();
		settings.Type__c = 'Apex Based';

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(TEST_SIZE, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldCleanseQueryWhereClause() {
		// Query-based logic should work even if users accidentally add a WHERE key as part of the clause
		GarbageCollector__mdt settings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		settings.QueryWhereClause__c = 'where CreatedDate = LAST_N_DAYS:365';
		settings.Type__c = 'Query Based';

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(TEST_SIZE, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldNotProcessIfInactive() {
		GarbageCollector__mdt settings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		settings.Active__c = false;

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<AsyncApexJob> jobs = GarbageCollectorTestUtils.getBatchJobs();
		Assert.areEqual(0, jobs?.size(), 'Wrong # of Batch Jobs');
		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(0, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleNoDefinedGarbageCollectors() {
		// Without the presence of GarbageCollector__mdts in an org, the launch method won't do anything
		GarbageCollectorMetadataSelector.settings = new Map<String, GarbageCollector__mdt>();

		Test.startTest();
		Id jobId = new GarbageCollector()?.launch();
		Test.stopTest();

		Assert.areEqual(null, jobId, 'Job launched anyways');
	}

	@IsTest
	static void shouldLaunchNextBatchJobInChain() {
		// The finish method will launch a new instance of the batch job
		// for the next GarbageCollector__mdt, if there is one
		// * Note: There can only be one batch enqueued in an @IsTest context,
		// so this is the only way we can test batch chaining logic
		GarbageCollectorTestUtils.initTestSettings(Account.SObjectType);
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		GarbageCollector job = new GarbageCollector();

		Test.startTest();
		job?.finish(null);
		Test.stopTest();

		// Assert that a new instance of the job was enqueued
		List<AsyncApexJob> jobs = GarbageCollectorTestUtils.getBatchJobs();
		Assert.areEqual(1, jobs?.size(), 'Wrong # of Batch Jobs');
		// Confirm that the records in this new job were deleted
		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(10, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldNotLaunchNewJobIfLastInChain() {
		// * The finish method will not launch a new instance of the batch job
		// if there isn't another GarbageCollector__mdt to process
		// * Note: There can only be one batch enqueued in an @IsTest context,
		// so this is the only way we can test batch chaining logic
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		GarbageCollector job = new GarbageCollector();

		Test.startTest();
		job?.finish(null);
		Test.stopTest();

		// Since there's nothing to be processed after the current settings, the job will complete
		List<AsyncApexJob> jobs = GarbageCollectorTestUtils.getBatchJobs();
		Assert.areEqual(0, jobs?.size(), 'Wrong # of Batch Jobs');
	}

	@IsTest
	static void shouldHandleBadApexClassName() {
		GarbageCollector__mdt badSettings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		badSettings.ApexClassName__c = 'abcd1234'; // Not a real apex class name
		badSettings.Type__c = 'Apex Based';

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(0, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleMissingApexClassName() {
		GarbageCollector__mdt badSettings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		badSettings.ApexClassName__c = null; // Should cause a null pointer exception for Type.forName() calls
		badSettings.Type__c = 'Apex Based';

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(0, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleBadQuery() {
		GarbageCollector__mdt badSettings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		badSettings.QueryWhereClause__C = 'abcd1234'; // Not a valid where clause
		badSettings.Type__c = 'Query Based';

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(0, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleMissingQuery() {
		GarbageCollector__mdt badSettings = GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		badSettings.QueryWhereClause__C = null;
		badSettings.Type__c = 'Query Based';

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(0, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleFailedDeletions() {
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		Task badTask = [SELECT Id FROM Task LIMIT 1]?.get(0);
		GarbageCollector.dml = new FailingDml()?.fail(badTask);

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		// Assert that all of the other records were deleted
		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(TEST_SIZE - 1, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleUnexpectedErrors() {
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		GarbageCollector.dml = new FatalErrorDml();

		Test.startTest();
		new GarbageCollector()?.launch();
		Test.stopTest();

		// Confirm that none of the records were deleted
		List<Task> tasks = GarbageCollectorTest.getDeletedTasks();
		Assert.areEqual(0, tasks?.size(), 'Wrong # of deleted Tasks');
	}

	@IsTest
	static void shouldHandleErrorsWhileRelaunching() {
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);
		GarbageCollectorTestUtils.initTestSettings(Contact.SObjectType);
		// Initialize a job with an injected exception in the launch() method
		GarbageCollector job = new BadCollector();

		Test.startTest();
		job?.finish(null);
		Test.stopTest();

		// Assert that a job was not launched
		List<AsyncApexJob> jobs = GarbageCollectorTestUtils.getBatchJobs();
		Assert.areEqual(0, jobs?.size(), 'Wrong # of Batch Jobs');
	}

	// **** HELPER **** //
	@TestSetup
	static void setup() {
		// Create a bunch of records to be deleted
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < TEST_SIZE; i++) {
            Task task = new Task();
            tasks?.add(task); 
        }
		insert tasks;
	}

	static List<Task> getDeletedTasks() {
		return [SELECT Id FROM Task WHERE IsDeleted = TRUE ALL ROWS];
	}

	// **** INNER **** //
	private class BadCollector extends GarbageCollector {
		public override Id launch() {
			// This type always throws an exception while attempting to launch a new instance of the job
			throw new System.AsyncException('This is a test');
		}
	}

	private class FailingDml extends GarbageCollector.Dml {
		Set<Id> failedRecordIds = new Set<Id>();

		private FailingDml fail(SObject record) {
			this.failedRecordIds?.add(record?.Id);
			return this;
		}

		public override List<Database.DeleteResult> deleteRecords(List<SObject> records) {
			Map<Id, SObject> recordMap = new Map<Id, SObject>(records);
			List<Database.DeleteResult> results = new List<Database.DeleteResult>();
			for (Id recordId : this.failedRecordIds) {
				recordMap?.remove(recordId);
				Database.DeleteResult mockResult = (Database.DeleteResult) new GarbageCollectorTestUtils.MockDmlResult(recordId)
                    ?.withError()
                    ?.toDatabaseResult(Database.DeleteResult.class);
				results?.add(mockResult);
			}
			results?.addAll(Database.delete(recordMap?.values()));
			return results;
		}
	}

	private class FatalErrorDml extends GarbageCollector.Dml {
		public override List<Database.DeleteResult> deleteRecords(List<SObject> records) {
			// This is just a proxy to surface up an unexpected error
			throw new System.IllegalArgumentException('This is a test');
		}
	}

	public class TestLocator implements GarbageCollector.QueryLocator {
		public Database.QueryLocator getQueryLocator() {
			return Database.getQueryLocator([SELECT Id FROM Task]);
		}
	}
}
