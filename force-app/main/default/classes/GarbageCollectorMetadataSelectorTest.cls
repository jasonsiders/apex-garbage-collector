@IsTest
private class GarbageCollectorMetadataSelectorTest {
	@IsTest
	static void shouldGetAllFromDatabase() {
		Integer numExpected = GarbageCollector__mdt.getAll()?.size();

		Test.startTest();
		List<GarbageCollector__mdt> garbageCollectors = GarbageCollectorMetadataSelector.getAll()?.values();
		Test.stopTest();

		Assert.areEqual(numExpected, garbageCollectors?.size(), 'Wrong # of GarbageCollector__mdt records retrieved');
	}

    @IsTest
	static void shouldGetAllFromInjectedResults() {
		String name = 'Test_Record';
        GarbageCollector__mdt mockRecord = new GarbageCollector__mdt(DeveloperName = name);
		GarbageCollectorMetadataSelector.settings = new Map<String, GarbageCollector__mdt>{ name => mockRecord };

		Test.startTest();
		List<GarbageCollector__mdt> garbageCollectors = GarbageCollectorMetadataSelector.getAll()?.values();
		Test.stopTest();

		Assert.areEqual(1, garbageCollectors?.size(), 'Wrong # of GarbageCollector__mdt records retrieved');
		Assert.areEqual(name, garbageCollectors?.get(0)?.DeveloperName, 'Wrong DeveloperName');
	}

    @IsTest 
    static void shouldGetSingleRecordFromInjectedResults() {
        String name = 'Test_Record';
        GarbageCollector__mdt mockRecord = new GarbageCollector__mdt(DeveloperName = name);
		GarbageCollectorMetadataSelector.settings = new Map<String, GarbageCollector__mdt>{ name => mockRecord };

		Test.startTest();
		GarbageCollector__mdt garbageCollector = GarbageCollectorMetadataSelector.get(name);
		Test.stopTest();

		Assert.areNotEqual(null, garbageCollector, 'Did not return a garbage collector');
    }

    @IsTest 
    static void shouldHandleNonExistentRecords() {
        // If metadata record with a matching developername doesn't exist, the method will return null
        String illegalName = 'abcd_1234__c'; // This is an illegal developer name; it'll never exist in any org

        Test.startTest();
		GarbageCollector__mdt garbageCollector = GarbageCollectorMetadataSelector.get(illegalName);
		Test.stopTest();

		Assert.areEqual(null, garbageCollector, 'Returned a garbage collector');
    }

	@IsTest
	static void shouldOnlyQueryOnce() {
		Test.startTest();
		for (Integer i = 0; i < 200; i++) {
			GarbageCollectorMetadataSelector.getAll();
		}
		Assert.areEqual(1, Limits.getQueries(), 'Did not cache query results');
		Test.stopTest();
	}

    @IsTest 
    static void shouldMapByDeveloperName() {
        // This is mostly for test coverage in orgs that do not have any GarbageCollector__mdt records defined
        String name = 'Test_Record';
        GarbageCollector__mdt mockRecord = new GarbageCollector__mdt(DeveloperName = name);
        List<GarbageCollector__mdt> mockRecords = new List<GarbageCollector__mdt>{ mockRecord };

        Test.startTest();
        Map<String, GarbageCollector__mdt> settingsMap = GarbageCollectorMetadataSelector.mapByDeveloperName(mockRecords);
        Test.stopTest();
        
        Assert.areEqual(1, settingsMap?.size(), 'Wrong # of settings');
        Assert.areEqual(true, settingsMap?.containsKey(name), name + ' was not mapped');
    }
}
