@IsTest 
private class GarbageCollectorSchedulableTest {
    @IsTest
	static void shouldLaunchJobFromSchedulable() {
		GarbageCollectorTestUtils.initTestSettings(Task.SObjectType);

		Test.startTest();
		new GarbageCollectorSchedulable()?.execute(null);
		Test.stopTest();

		List<AsyncApexJob> jobs = GarbageCollectorTestUtils.getBatchJobs();
		Assert.areEqual(1, jobs?.size(), 'Wrong # of Batch Jobs');
	}
}