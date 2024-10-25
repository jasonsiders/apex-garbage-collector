@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
@IsTest 
global class GarbageCollectorTestUtils {
    private GarbageCollectorTestUtils() {
        // Necessary since @IsTest classes cannot also be abstract
    }

    global static void inject(GarbageCollector__mdt mockRecord) {
        GarbageCollectorMetadataSelector.init();
        String name = mockRecord?.DeveloperName;
        GarbageCollectorMetadataSelector.settings?.put(name, mockRecord);
    }
}