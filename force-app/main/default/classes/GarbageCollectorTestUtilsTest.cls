@IsTest
private class GarbageCollectorTestUtilsTest {
    @IsTest 
    static void shouldMockGarbageCollector() {
        String name = 'abcd_1234';
        GarbageCollector__mdt mockRecord = new GarbageCollector__mdt(DeveloperName = name);

        Test.startTest();
        GarbageCollectorTestUtils.inject(mockRecord);
        Test.stopTest();

        Assert.isTrue(GarbageCollectorMetadataSelector.settings?.containsKey(name), 'Did not inject ' + name);
    }
}